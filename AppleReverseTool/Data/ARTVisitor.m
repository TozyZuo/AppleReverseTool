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
#import "ARTiVar.h"
#import "ARTDataController.h"


@interface ARTVisitor ()
@property (nonatomic, strong) NSString *frameworkName;
@property (nonatomic, strong) NSString *className;

@property (nonatomic,  weak ) ARTDataController *dataController;
@property (nonatomic,  copy ) void (^progress)(NSString *, NSString *, NSString *);
@property (nonatomic, strong) NSMutableDictionary<NSString *, CDOCProtocol *> *protocolsByProtocolStringInMainFile;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CDOCProtocol *> *protocolsByProtocolString;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CDOCClass *> *classesByClassStringInMainFile;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CDOCClass *> *classesByClassString;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, CDOCCategory *> *> *categoriesByClassStringInMainFile;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, CDOCCategory *> *> *categoriesByClassString;
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
        self.protocolsByProtocolStringInMainFile = [[NSMutableDictionary alloc] init];
        self.protocolsByProtocolString = [[NSMutableDictionary alloc] init];
        self.classesByClassStringInMainFile = [[NSMutableDictionary alloc] init];
        self.classesByClassString = [[NSMutableDictionary alloc] init];
        self.categoriesByClassStringInMainFile = [[NSMutableDictionary alloc] init];
        self.categoriesByClassString = [[NSMutableDictionary alloc] init];
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
    if (self.protocolsByProtocolStringInMainFile[protocol.name]) {
        return;
    }

    [super willVisitProtocol:protocol];

    protocol.isInsideMainBundle = self.isCurrentFrameworkInsideMainFile;
    self.protocolsByProtocolString[protocol.name] = protocol;
    if (self.isCurrentFrameworkInsideMainFile) {
        self.protocolsByProtocolStringInMainFile[protocol.name] = protocol;
    }

    self.className = protocol.name;
    if (self.progress) {
        self.progress(self.frameworkName, protocol.name, nil);
    }
    
}

- (void)willVisitClass:(CDOCClass *)aClass
{
    if (self.classesByClassStringInMainFile[aClass.name]) {
        return;
    }

    [super willVisitClass:aClass];

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

- (void)willVisitCategory:(CDOCCategory *)category
{
    if (self.categoriesByClassStringInMainFile[category.className][category.name]) {
        return;
    }

    [super willVisitCategory:category];

    category.isInsideMainBundle = self.isCurrentFrameworkInsideMainFile;

    NSMutableDictionary *categories = self.categoriesByClassString[category.className];
    if (!categories) {
        categories = [[NSMutableDictionary alloc] init];
        self.categoriesByClassString[category.className] = categories;
    }
    categories[category.name] = category;

    if (self.isCurrentFrameworkInsideMainFile) {
        categories = self.categoriesByClassStringInMainFile[category.className];
        if (!categories) {
            categories = [[NSMutableDictionary alloc] init];
            self.categoriesByClassStringInMainFile[category.className] = categories;
        }
        categories[category.name] = category;
    }

    self.className = [NSString stringWithFormat:@"%@(%@)", category.className, category.name];
    if (self.progress) {
        self.progress(self.frameworkName, self.className, nil);
    }
}

- (void)visitIvar:(CDOCInstanceVariable *)ivar
{
    [super visitIvar:ivar];
    ivar.type.dataController = self.dataController;

    if (self.progress) {
        self.progress(self.frameworkName, self.className, [self.classDump.typeController.ivarTypeFormatter formatVariable:ivar.name type:ivar.type]);
    }
}

- (void)didEndVisiting
{
    [super didEndVisiting];

    // merge all
    [self.classesByClassString enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, CDOCClass * _Nonnull class, BOOL * _Nonnull stop)
    {
        class.superClassRef.classObject = self.classesByClassString[class.superClassName];
        if (class.protocols.count) {
            NSMutableArray *protocols = [[NSMutableArray alloc] init];
            for (CDOCProtocol *protocol in class.protocols) {
                [protocols addObject:self.protocolsByProtocolString[protocol.name] ?: protocol];
            }
            class[@"protocols"] = protocols;
        }

        [self.categoriesByClassString[class.name] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull name, CDOCCategory * _Nonnull category, BOOL * _Nonnull stop)
        {
            category.classRef.classObject = class;
            [class addCategory:category];
        }];
    }];
}

@end
