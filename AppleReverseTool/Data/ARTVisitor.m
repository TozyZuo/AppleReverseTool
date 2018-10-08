//
//  ARTVisitor.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/9/29.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTVisitor.h"
#import "CDObjectiveCProcessor.h"
#import "CDMachOFile.h"
#import "CDOCClassReference.h"
#import "CDClassDump.h"
#import "CDTypeController.h"
#import "CDTypeFormatter.h"
#import "CDOCInstanceVariable.h"
#import "ClassDumpExtension.h"
#import "ARTClass.h"
#import "ARTiVar.h"
#import "ARTDataController.h"


@interface ARTVisitor ()
@property (nonatomic, strong) NSString *frameworkName;
@property (nonatomic, strong) NSString *className;

@property (nonatomic,  weak ) ARTDataController *dataController;
@property (nonatomic,  copy ) void (^progress)(NSString *, NSString *, NSString *);
//@property (nonatomic, strong) NSMutableDictionary<NSString *, ARTClass *> *classesByClassStringInMainFile;
//@property (nonatomic, strong) NSMutableDictionary<NSString *, ARTClass *> *classesByClassString;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CDOCProtocol *> *protocolsByProtocolString;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CDOCClass *> *classesByClassStringInMainFile;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CDOCClass *> *classesByClassString;
@property (nonatomic, strong) NSMutableDictionary<NSString *, ARTiVar *> *iVarsByiVarType;
@property (nonatomic, strong) NSArray *mainFileRunPaths;
@property (nonatomic, assign) BOOL isCurrentFrameworkInsideMainFile;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *classesByFrameworkName;
@end

@implementation ARTVisitor

- (instancetype)initWithDataController:(ARTDataController *)dataController progress:(void (^ _Nullable)(NSString * _Nullable, NSString * _Nullable, NSString * _Nullable))progress
{
    self = [super init];
    if (self) {
        self.dataController = dataController;
        self.progress = progress;
        self.protocolsByProtocolString = [[NSMutableDictionary alloc] init];
        self.classesByClassStringInMainFile = [[NSMutableDictionary alloc] init];
        self.classesByClassString = [[NSMutableDictionary alloc] init];
        self.iVarsByiVarType = [[NSMutableDictionary alloc] init];
        self.classesByFrameworkName = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)willVisitObjectiveCProcessor:(CDObjectiveCProcessor *)processor;
{
    self.isCurrentFrameworkInsideMainFile = NO;
    NSString *frameworkName = processor.machOFile.importBaseName;
    if (!frameworkName || [processor.machOFile.filename isEqualToString:self.dataController.filePath])
    {
        frameworkName = self.dataController.filePath.lastPathComponent;
        // 去重
        NSMutableSet *mainFileRunPaths = [NSMutableSet set];
        for (NSString *path in processor.machOFile.runPaths) {
            [mainFileRunPaths addObject:path];
        }
        self.mainFileRunPaths = mainFileRunPaths.allObjects;
        self.isCurrentFrameworkInsideMainFile = YES;
    }
    self.frameworkName = frameworkName;

    for (NSString *mainFileRunPath in self.mainFileRunPaths) {
        if ([processor.machOFile.filename hasPrefix:mainFileRunPath]) {
            self.isCurrentFrameworkInsideMainFile = YES;
            break;
        }
    }

    if (self.progress) {
        self.progress(self.frameworkName, nil, nil);
    }
}

- (void)willVisitProtocol:(CDOCProtocol *)protocol
{
    [super willVisitProtocol:protocol];

    protocol.isInsideMainBundle = self.isCurrentFrameworkInsideMainFile;
    self.protocolsByProtocolString[protocol.name] = protocol;

    self.className = protocol.name;
    if (self.progress) {
        self.progress(self.frameworkName, protocol.name, nil);
    }
    
}

- (void)willVisitClass:(CDOCClass *)aClass
{
    [super willVisitClass:aClass];

//    ARTClass *class = [[ARTClass alloc] initWithClass:aClass bundleName:self.frameworkName];
    CDOCClass *class = (CDOCClass *)aClass;
    class.isInsideMainBundle = self.isCurrentFrameworkInsideMainFile;

    self.classesByClassString[aClass.name] = class;
    if (self.isCurrentFrameworkInsideMainFile) {
        self.classesByClassStringInMainFile[aClass.name] = class;
    }

    self.className = aClass.name;
    if (self.progress) {
        self.progress(self.frameworkName, aClass.name, nil);
    }

    // TODO
    NSMutableArray *classes = self.classesByFrameworkName[self.frameworkName];
    if (!classes) {
        classes = [[NSMutableArray alloc] init];
        self.classesByFrameworkName[self.frameworkName] = classes;
    }
    [classes addObject:aClass.name];
}

- (void)visitIvar:(CDOCInstanceVariable *)ivar
{
    [super visitIvar:ivar];
    ivar.type.dataController = self.dataController;

    // TODO

    if (self.progress) {
        self.progress(self.frameworkName, self.className, [self.classDump.typeController.ivarTypeFormatter formatVariable:ivar.name type:ivar.type]);
    }
}

- (void)didEndVisiting
{
    [super didEndVisiting];

    [self.classesByClassString enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, CDOCClass * _Nonnull obj, BOOL * _Nonnull stop)
    {
        obj.superClassRef.classObject = self.classesByClassString[obj.superClassName];
        if (obj.protocols.count) {
            NSMutableArray *protocols = [[NSMutableArray alloc] init];
            for (CDOCProtocol *protocol in obj.protocols) {
                [protocols addObject:self.protocolsByProtocolString[protocol.name] ?: protocol];
            }
            obj[@"protocols"] = protocols;
        }
    }];
}

@end
