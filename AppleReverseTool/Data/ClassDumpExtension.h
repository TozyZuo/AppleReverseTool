//
//  ClassDumpExtension.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/3.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CRNode.h"
#import "CDOCClass.h"
#import "CDOCCategory.h"
#import "CDOCClassReference.h"
#import "CDType.h"
#import "CDTypeName.h"
#import "CDTypeFormatter.h"
#import "CDTypeController.h"
#import "CDStructureTable.h"
#import "CDStructureInfo.h"

#define _S ARTStringCreate
#define _SC ARTColorStringCreate
#define _SF(...) [NSString stringWithFormat:__VA_ARGS__]

#define _CS(string) (ARTConfigManager.sharedManager.hideComments ? @"" : _SC(string, kColorComments))

#define _CL(aClass) _SC(ARTLinkStringCreate(kSchemeClass, aClass.name, aClass.name), aClass.isInsideMainBundle ? kColorClass : kColorOtherClass)
#define _CGL(category) _SC(ARTLinkStringCreate(kSchemeCategory, _S(category.className, @"/", category.name, nil), category.name), category.isInsideMainBundle ? kColorClass : kColorOtherClass)
#define _PL(protocol) _S(_SC(ARTLinkStringCreate(kSchemeProtocol, protocol.name, protocol.name), protocol.isInsideMainBundle ? kColorClass : kColorOtherClass), _BL(protocol), nil)
#define _BL(objectWithBundle) (ARTConfigManager.sharedManager.showBundle ? [NSString stringWithFormat:@"<font size=%.0f><a href='%@://%@' color=%@>[%@]</a></font>", ceilf(NSFontManager.sharedFontManager.selectedFont.pointSize * .5), kSchemeBundle, objectWithBundle.bundleName, kColorBundle, objectWithBundle.bundleName] : @"")

#define _CNL(className) _SC(ARTLinkStringCreate(kSchemeClass, className, className), self.dataController.classForName(className).isInsideMainBundle ? kColorClass : kColorOtherClass)
#define _PNL(protocolName) _SC(ARTLinkStringCreate(kSchemeProtocol, protocolName, protocolName), self.dataController.allProtocols[protocolName].isInsideMainBundle ? kColorClass : kColorOtherClass)
#define _SNL(structName) ARTLinkStringCreate(kSchemeStruct, _S(self.typeString, @"/", structName, nil), structName)
#define _UNL(structName) ARTLinkStringCreate(kSchemeUnion, _S(self.typeString, @"/", structName, nil), structName)


NS_ASSUME_NONNULL_BEGIN

extern NSString *ARTStringCreate(NSString *string, ...) NS_REQUIRES_NIL_TERMINATION;

NS_INLINE NSString *ARTColorStringCreate(NSString *string, NSString *color)
{
    return [NSString stringWithFormat:@"<font color=%@>%@</font>", color, string];
}

NS_INLINE NSString *ARTLinkStringCreate(NSString *scheme, NSString *path, NSString *string)
{
    return [NSString stringWithFormat:@"<a href='%@://%@'>%@</a>", scheme, path, string];
}

@class ARTDataController;

#pragma mark -

@interface CDOCProtocol (ARTExtension)
<NSCopying>
@property (nonatomic, assign) BOOL isInsideMainBundle;
@property (nonatomic, strong) NSString *bundleName;
@end

@interface CDOCClass (ARTExtension)
<ARTNode>
@property (  weak  ) CDOCClass *superClass;
@property (readonly) NSArray<CDOCClass *> *referrers;
@property (readonly) NSArray<CDOCCategory *> *categories;
- (void)addCategory:(CDOCCategory *)category;
- (void)addReferrer:(CDOCClass *)referrer;
- (void)sort;
@end

@interface CDOCCategory (ARTExtension)
<NSCopying>
@property ( weak ) CDOCClass *classReference;
@end

@interface CDOCClassReference (ARTExtension)
<NSCopying>
@end

typedef NS_ENUM(NSInteger, CDDetailedType) {
    CDDetailedTypeSimple,
    CDDetailedTypeArray,
    CDDetailedTypeBitFields,
    CDDetailedTypeUnion,
    CDDetailedTypeStruct,
    CDDetailedTypePointer,
    CDDetailedTypeFunctionPointer,
    CDDetailedTypeBlock,
    CDDetailedTypeID,
    CDDetailedTypeNamedObject,
    CDDetailedTypeVoid,
};

@interface CDType (ARTExtension)
@property (nonatomic,  assign ) BOOL isInsideMainBundle; // TODO struct
@property (nonatomic, readonly) CDDetailedType detailedType;
- (void)setIsParsing:(BOOL)isParsing; // compiled trick, never be invoked
- (void)setDataController:(ARTDataController *)dataController; // compiled trick, never be invoked
@end

@interface CDTypeController (ARTExtension)
@property (readonly) CDStructureTable *structureTable;
@property (readonly) CDStructureTable *unionTable;
- (NSString *)structDescriptionWithStructureInfo:(CDStructureInfo *)info;
- (NSString *)structDisplayDescriptionWithStructureInfo:(CDStructureInfo *)info;
@end

@interface CDStructureTable (ARTExtension)
@property (readonly) NSDictionary<NSString */*name*/, CDStructureInfo *> *namedStructureInfo;
@property (readonly) NSDictionary<NSString */*reallyBareTypeString*/, CDStructureInfo *> *anonStructureInfo;
@property (readonly) NSDictionary<NSString */*typeString*/, CDStructureInfo *> *nameExceptions;
@property (readonly) NSDictionary<NSString */*typeString*/, CDStructureInfo *> *anonExceptions;
@end

@interface CDStructureInfo (ARTExtension)
@property (readonly) NSString *structDescription;
@property (readonly) NSString *structDisplayDescription;
@end

#pragma mark -

@interface ARTTypeFormatter : CDTypeFormatter
@property (nonatomic, weak) ARTDataController *dataController;
@end

@interface ARTTypeController : CDTypeController
@property (readonly) ARTTypeFormatter *ivarTypeFormatter;
@property (readonly) ARTTypeFormatter *methodTypeFormatter;
@property (readonly) ARTTypeFormatter *propertyTypeFormatter;
@end

@interface ARTType : CDType
@property (nonatomic, assign) BOOL isParsing;
@property (nonatomic,  weak ) ARTDataController *dataController;
@end

@interface ARTTypeName : CDTypeName
@property (nonatomic, assign) BOOL isParsing;
@property (nonatomic,  weak ) CDType *type;
@property (nonatomic,  weak ) ARTDataController *dataController;
@end

NS_ASSUME_NONNULL_END
