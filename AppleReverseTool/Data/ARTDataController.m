//
//  ARTDataController.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/9/28.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTDataController.h"
#import "CDMachOFile.h"
#import "CDFatFile.h"
#import "CDClassDump.h"
#import "ClassDumpExtension.h"
#import "CDTypeController.h"
#import "CDOCCategory.h"
#import "CDOCInstanceVariable.h"
#import "CDSearchPathState.h"
#import "CDObjectiveCProcessor.h"
#import "CDMethodType.h"
#import "ClassDumpHook.h"
#import "ARTVisitor.h"
#import "ARTClass.h"
#import "CRNode.h"
#import "ARTDefine.h"
#import <objc/runtime.h>

@interface ARTDataController ()
<ARTNodeProvider>
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic,  weak ) ARTVisitor *visitor;
@property (nonatomic, strong) CDTypeController *typeController;
@property (nonatomic, strong) NSArray<CDOCClass *> *classNodes;
@property (nonatomic, strong) NSDictionary<NSString *, CDOCClass *> *allClasses;
@property (nonatomic, strong) NSDictionary<NSString *, CDOCProtocol *> *allProtocols;
@property (class) BOOL isInDataProcessing;
@end

@implementation ARTDataController

- (instancetype)initWithFileURL:(NSURL *)fileURL
{
    self = [super init];
    if (self) {
//
//        NSString *str = DescriptionWithNodes(self.classNodes);
//        NSLog(@"%@", str);
//        self.classNodes = nil;
    }
    return self;
}

#pragma mark - Private

static BOOL _isInDataProcessing = NO;

+ (BOOL)isInDataProcessing
{
    @synchronized (self) {
        return _isInDataProcessing;
    }
}

+ (void)setIsInDataProcessing:(BOOL)isInDataProcessing
{
    @synchronized (self) {
        _isInDataProcessing = isInDataProcessing;
    }
}

- (void)exchangeClassDumpMethods
{
    if (!ARTDataController.isInDataProcessing) {
        // data
        method_exchangeImplementations(class_getInstanceMethod(CDObjectiveCProcessor.class, @selector(process)), class_getInstanceMethod(CDObjectiveCProcessor.class, @selector(hook_process)));
        method_exchangeImplementations(class_getInstanceMethod(CDOCProtocol.class, @selector(setName:)), class_getInstanceMethod(CDOCProtocol.class, @selector(hook_setName:)));
        method_exchangeImplementations(class_getInstanceMethod(CDOCCategory.class, @selector(setClassRef:)), class_getInstanceMethod(CDOCCategory.class, @selector(hook_setClassRef:)));
        method_exchangeImplementations(class_getInstanceMethod(CDOCInstanceVariable.class, @selector(initWithName:typeString:offset:)), class_getInstanceMethod(CDOCInstanceVariable.class, @selector(hook_initWithName:typeString:offset:)));
        // type
        method_exchangeImplementations(class_getInstanceMethod(CDObjectiveCProcessor.class, @selector(registerTypesWithObject:phase:)), class_getInstanceMethod(CDObjectiveCProcessor.class, @selector(hook_registerTypesWithObject:phase:)));
        method_exchangeImplementations(class_getInstanceMethod(CDOCProtocol.class, @selector(registerTypesWithObject:phase:)), class_getInstanceMethod(CDOCProtocol.class, @selector(hook_registerTypesWithObject:phase:)));
        method_exchangeImplementations(class_getInstanceMethod(CDMethodType.class, @selector(initWithType:offset:)), class_getInstanceMethod(CDMethodType.class, @selector(hook_initWithType:offset:)));
    }
}

#pragma mark - Public

- (void)processDataWithFilePath:(NSString *)path progress:(void (^ _Nullable)(ARTDataControllerProcessState, NSString * _Nullable, NSString * _Nullable, NSString * _Nullable, NSString * _Nullable))progress completion:(nonnull void (^)(ARTDataController * _Nonnull))completion
{
    self.filePath = path;

    dispatch_queue_t queue = dispatch_queue_create(path.lastPathComponent.UTF8String, DISPATCH_QUEUE_SERIAL);
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    dispatch_queue_set_specific(queue, _dispatch_queue_userInfo_key, (__bridge void * _Nullable)(userInfo), NULL);

    dispatch_async(queue, ^{

        CDSearchPathState *searchPathState = [[CDSearchPathState alloc] init];
        searchPathState.executablePath = path.stringByDeletingLastPathComponent;
        CDFile * file = [CDFile fileWithContentsOfFile:path searchPathState:searchPathState];

        if ([file isKindOfClass:[CDFatFile class]] ) {
            fprintf(stderr,"Restore-symbol supports armv7 and arm64 archtecture, but not support fat file. Please use lipo to thin the image file first.");
            exit(1);
        }

        CDMachOFile * machOFile = (CDMachOFile *)file;

        CDClassDump *classDump = [[CDClassDump alloc] init];

        ARTTypeController *typeController = [[ARTTypeController alloc] initWithClassDump:classDump];
        typeController.ivarTypeFormatter.dataController = self;
        typeController.methodTypeFormatter.dataController = self;
        typeController.propertyTypeFormatter.dataController = self;

        classDump[@"typeController"] = typeController;
        CDArch targetArch;
        if (![machOFile bestMatchForLocalArch:&targetArch]) {
            fprintf(stderr, "Error: Couldn't get local architecture!\n");
            exit(1);
        }
        classDump.targetArch = targetArch;
        classDump.shouldProcessRecursively = YES;

        if ((targetArch.cputype & CPU_TYPE_ARM) == CPU_TYPE_ARM) {
            classDump.sdkRoot = @"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot";
        }

        NSError *error;
        if (![classDump loadFile:machOFile error:&error]) {
            fprintf(stderr, "Error: %s\n", [[error localizedFailureReason] UTF8String]);
            exit(1);
        } else {
            if (progress) {
                TZInvokeBlockInMainThread(^{
                    progress(ARTDataControllerProcessStateWillProcess, nil, nil, nil, nil);
                })
            }

            if (progress) {
                userInfo[@"progress"] = ^(ARTDataControllerProcessState state, NSString * _Nullable framework, NSString * _Nullable class, NSString * _Nullable iVar, NSString * _Nullable type)
                {
                    TZInvokeBlockInMainThread(^{
                        progress(state, framework, class, iVar, type);
                    })
                };
            }

            [self exchangeClassDumpMethods];
            ARTDataController.isInDataProcessing = YES;

            ARTVisitor *visitor = [[ARTVisitor alloc] initWithDataController:self progress:nil];
            visitor.classDump = classDump;
            [classDump processObjectiveCData];
            [classDump registerTypes];

            ARTDataController.isInDataProcessing = NO;
            [self exchangeClassDumpMethods];

            if (progress) {
                TZInvokeBlockInMainThread(^{
                    progress(ARTDataControllerProcessStateDidProcess, nil, nil, nil, nil);
                })
            }
            [classDump recursivelyVisit:visitor];
            visitor.classDump = nil;

            self.visitor = visitor;
            self.typeController = classDump.typeController;
            self.allClasses = visitor.classesByClassString;
            self.allProtocols = visitor.protocolsByProtocolString;
            self.classNodes = (NSArray<CDOCClass *> *)NodesWithProvider(self);
        }

        if (completion) {
            TZInvokeBlockInMainThread(^{
                completion(self);
            })
        }
    });
}

#pragma mark - ARTNodeProvider

- (NSArray<id<ARTNode>> *)nodes
{
    return self.visitor.classesByClassStringInMainFile.allValues;
}

- (id<ARTNode>)superNodeForNode:(ARTClass *)node
{
    return self.visitor.classesByClassString[node.superClassName];
}

@end
