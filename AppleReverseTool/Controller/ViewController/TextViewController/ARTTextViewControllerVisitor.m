//
//  ARTTextViewControllerVisitor.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/3.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTTextViewControllerVisitor.h"
#import "ARTDataController.h"
#import "ARTConfigManager.h"
#import "ClassDumpExtension.h"
#import "CDOCClassReference.h"
#import "CDOCMethod.h"
#import "CDOCProperty.h"
#import "CDTypeFormatter.h"
#import "CDVisitorPropertyState.h"
#import "CDOCInstanceVariable.h"
#import "CDTypeLexer.h"
#import "CDMethodType.h"
#import <objc/runtime.h>


static BOOL debug = NO;

@interface ARTTextViewControllerVisitor ()
@property (nonatomic, strong) CDTypeController *typeController;
@property (nonatomic,  weak ) ARTDataController *dataController;
@property (nonatomic, strong) NSMutableString *propertiesString;
@property (nonatomic, strong) NSMutableString *classMethodsString;
@property (nonatomic, strong) NSMutableString *instanceMethodsString;
@property (nonatomic, strong) NSMutableString *optionalPropertiesString;
@property (nonatomic, strong) NSMutableString *optionalClassMethodsString;
@property (nonatomic, strong) NSMutableString *optionalInstanceMethodsString;

@property (nonatomic, strong) NSMutableArray *properties;
@property (nonatomic, strong) NSMutableArray *classMethods;
@property (nonatomic, strong) NSMutableArray *instanceMethods;
@property (nonatomic, strong) NSMutableArray *optionalProperties;
@property (nonatomic, strong) NSMutableArray *remainingProperties;
@property (nonatomic, strong) NSMutableArray *optionalClassMethods;
@property (nonatomic, strong) NSMutableArray *optionalInstanceMethods;
@property (nonatomic,  weak ) NSMutableArray *currentProperties;
@property (nonatomic,  weak ) NSMutableArray *currentClassMethods;
@property (nonatomic,  weak ) NSMutableArray *currentInstanceMethods;

@end

@implementation ARTTextViewControllerVisitor

- (id)initWithTypeController:(CDTypeController *)typeController dataController:(nonnull ARTDataController *)dataController
{
    if ((self = [super init])) {
        _resultString = [[NSMutableString alloc] init];
        self.typeController = typeController;
        self.dataController = dataController;

        self.properties = [[NSMutableArray alloc] init];
        self.classMethods = [[NSMutableArray alloc] init];
        self.instanceMethods = [[NSMutableArray alloc] init];
        self.optionalProperties = [[NSMutableArray alloc] init];
        self.remainingProperties = [[NSMutableArray alloc] init];
        self.optionalClassMethods = [[NSMutableArray alloc] init];
        self.optionalInstanceMethods = [[NSMutableArray alloc] init];
        self.currentProperties = self.properties;
        self.currentClassMethods = self.classMethods;
        self.currentInstanceMethods = self.instanceMethods;

        self.propertiesString = [[NSMutableString alloc] init];
        self.classMethodsString = [[NSMutableString alloc] init];
        self.instanceMethodsString = [[NSMutableString alloc] init];
        self.optionalPropertiesString = [[NSMutableString alloc] init];
        self.optionalClassMethodsString = [[NSMutableString alloc] init];
        self.optionalInstanceMethodsString = [[NSMutableString alloc] init];
    }

    return self;
}

#pragma mark - Sort

- (void)sortProperties:(NSMutableArray *)properties
{
    [properties sortUsingComparator:^NSComparisonResult(CDOCProperty * _Nonnull obj1, CDOCProperty * _Nonnull obj2)
    {
        CDDetailedType detailedType1 = obj1.type.detailedType;
        CDDetailedType detailedType2 = obj2.type.detailedType;
        if (detailedType1 == detailedType2) {
            if (detailedType1 == CDDetailedTypeNamedObject) {
                CDOCClass *c1 = self.dataController.classForName(obj1.type.typeName.name);
                CDOCClass *c2 = self.dataController.classForName(obj2.type.typeName.name);
                if (c1.isInsideMainBundle != c2.isInsideMainBundle) {
                    return c2.isInsideMainBundle ? NSOrderedAscending : NSOrderedDescending;
                }
            }
            return [obj1.name compare:obj2.name];
        } else {
            return detailedType1 < detailedType2 ? NSOrderedAscending : NSOrderedDescending;
        }
    }];
}

- (void)sortClassMethods:(NSMutableArray *)methods
{
    [methods sortUsingComparator:^NSComparisonResult(CDOCMethod * _Nonnull obj1, CDOCMethod * _Nonnull obj2)
    {
        CDMethodType *returnType1 = obj1.parsedMethodTypes.firstObject;
        CDMethodType *returnType2 = obj2.parsedMethodTypes.firstObject;
        CDDetailedType detailedType1 = returnType1.type.detailedType;
        CDDetailedType detailedType2 = returnType2.type.detailedType;
        if (detailedType1 == detailedType2) {
            return [obj1.name compare:obj2.name];
        } else {
            if (detailedType1 == CDDetailedTypeID) {
                return NSOrderedAscending;
            } else if (detailedType2 == CDDetailedTypeID) {
                return NSOrderedDescending;
            }
            return detailedType1 < detailedType2 ? NSOrderedAscending : NSOrderedDescending;
        }
    }];
}

- (void)sortInstanceMethods:(NSMutableArray *)methods
{
    [methods sortUsingComparator:^NSComparisonResult(CDOCMethod * _Nonnull obj1, CDOCMethod * _Nonnull obj2)
     {
         BOOL hasInit1 = [obj1.name hasPrefix:@"init"] || [obj1.name hasPrefix:@"_init"];
         BOOL hasInit2 = [obj2.name hasPrefix:@"init"] || [obj2.name hasPrefix:@"_init"];
         if (hasInit1 != hasInit2) {
             if (hasInit1) {
                 return NSOrderedAscending;
             } else if (hasInit2) {
                 return NSOrderedDescending;
             }
         }
         CDMethodType *returnType1 = obj1.parsedMethodTypes.firstObject;
         CDMethodType *returnType2 = obj2.parsedMethodTypes.firstObject;
         CDDetailedType detailedType1 = returnType1.type.detailedType;
         CDDetailedType detailedType2 = returnType2.type.detailedType;
         if (detailedType1 == detailedType2) {
             return [obj1.name compare:obj2.name];
         } else {
             return detailedType1 < detailedType2 ? NSOrderedAscending : NSOrderedDescending;
         }
     }];
}

#pragma mark - Visit

- (void)willEndVisit
{
    [self sortProperties:self.properties];
    for (CDOCProperty *property in self.properties) {
        [self visitProperty:property appendToString:self.propertiesString];
    }

    [self sortProperties:self.remainingProperties];
    if (self.remainingProperties.count) {
        [self.propertiesString appendString:@"\n"];
        [self.propertiesString appendString:_CS(@"// Remaining properties\n")];
        for (CDOCProperty *property in self.remainingProperties) {
            [self visitProperty:property appendToString:self.propertiesString];
        }
    }

    [self sortProperties:self.optionalProperties];
    for (CDOCProperty *property in self.optionalProperties) {
        [self visitProperty:property appendToString:self.optionalPropertiesString];
    }

    [self sortClassMethods:self.classMethods];
    for (CDOCMethod *method in self.classMethods) {
        [self.classMethodsString appendString:@"+ "];
        [method appendToString:self.classMethodsString typeController:self.typeController];
        [self.classMethodsString appendString:@"\n"];
    }

    [self sortClassMethods:self.optionalClassMethods];
    for (CDOCMethod *method in self.optionalClassMethods) {
        [self.optionalClassMethodsString appendString:@"+ "];
        [method appendToString:self.optionalClassMethodsString typeController:self.typeController];
        [self.optionalClassMethodsString appendString:@"\n"];
    }

    [self sortInstanceMethods:self.instanceMethods];
    for (CDOCMethod *method in self.instanceMethods) {
        [self.instanceMethodsString appendString:@"- "];
        [method appendToString:self.instanceMethodsString typeController:self.typeController];
        [self.instanceMethodsString appendString:@"\n"];
    }

    [self sortInstanceMethods:self.optionalInstanceMethods];
    for (CDOCMethod *method in self.optionalInstanceMethods) {
        [self.optionalInstanceMethodsString appendString:@"- "];
        [method appendToString:self.optionalInstanceMethodsString typeController:self.typeController];
        [self.optionalInstanceMethodsString appendString:@"\n"];
    }
}

#pragma mark Protocol

- (void)willVisitProtocol:(CDOCProtocol *)protocol;
{
    [self.resultString appendString:_S(_SC(@"@protocol ", kColorKeywords), _SC(protocol.name, protocol.isInsideMainBundle ? kColorClass : kColorOtherClass), _BL(protocol), nil)];

    NSArray *protocols = protocol.protocols;
    if (protocols.count) {

        [self.resultString appendString:@" <"];

        for (CDOCProtocol *protocol in protocols) {
            [self. resultString appendString:_S(_PL(protocol), @", ", nil)];
        }

        [self.resultString deleteCharactersInRange:NSMakeRange(self.resultString.length - 2, 2)];
        [self.resultString appendString:@">"];
    }

    [self.resultString appendString:@"\n"];
}

- (void)didVisitProtocol:(CDOCProtocol *)protocol;
{
    [self willEndVisit];

    [self.resultString appendString:self.propertiesString];
    [self.resultString appendString:self.classMethodsString];
    [self.resultString appendString:self.instanceMethodsString];
    if (self.optionalPropertiesString.length ||
        self.optionalClassMethodsString.length ||
        self.optionalInstanceMethodsString.length)
    {
        [self.resultString appendString:_SC(@"@optional\n", kColorKeywords)];
        [self.resultString appendString:self.optionalPropertiesString];
        [self.resultString appendString:self.optionalClassMethodsString];
        [self.resultString appendString:self.optionalInstanceMethodsString];
    }

    [self.resultString appendString:_SC(@"@end\n\n", kColorKeywords)];
}

#pragma mark Class

- (void)willVisitClass:(CDOCClass *)aClass;
{
    if (aClass.isExported == NO)
        [self.resultString appendString:_S(_SC(@"__attribute__", kColorKeywords), @"((visibility(", _SC(@"\"hidden\"", kColorStrings), @")))\n", nil)];

    [self.resultString appendString:_S(_SC(@"@interface ", kColorKeywords), _SC(aClass.name, aClass.isInsideMainBundle ? kColorClass : kColorOtherClass), nil)];

    if (aClass.superClassName != nil)
        [self.resultString appendString:_S(@" : ", _CL(aClass.superClass), nil)];

    NSArray *protocols = aClass.protocols;
    if (protocols.count) {

        [self.resultString appendString:@"\n<\n"];

        for (CDOCProtocol *protocol in protocols) {
            [self.resultString appendString:_S(@"\t", _PL(protocol), @",\n", nil)];
        }

        [self.resultString deleteCharactersInRange:NSMakeRange(self.resultString.length - 2, 2)];
        [self.resultString appendString:@"\n>"];
    }

    [self.resultString appendString:@"\n"];
}

- (void)didVisitClass:(CDOCClass *)aClass;
{
    [self willEndVisit];

    [self.resultString appendString:self.propertiesString];

    if (aClass.properties.count)
        [self.resultString appendString:@"\n"];

    [self.resultString appendString:self.classMethodsString];
    [self.resultString appendString:self.instanceMethodsString];

    if (self.classMethodsString.length || self.instanceMethodsString.length)
        [self.resultString appendString:@"\n"];

    [self.resultString appendString:_SC(@"@end\n\n", kColorKeywords)];
}

- (void)willVisitIvarsOfClass:(CDOCClass *)aClass;
{
    if (aClass.instanceVariables.count) {
        [self.resultString appendString:@"{\n"];
    }
}

- (void)visitIvar:(CDOCInstanceVariable *)ivar;
{
    CDType *type = ivar.type;
    type.isParsing = YES;
    [ivar appendToString:self.resultString typeController:self.typeController];
    type.isParsing = NO;
    [self.resultString appendString:@"\n"];
}

- (void)didVisitIvarsOfClass:(CDOCClass *)aClass;
{
    if (aClass.instanceVariables.count) {
        [self.resultString appendString:@"}\n\n"];
    }
}

#pragma mark Category

- (void)willVisitCategory:(CDOCCategory *)category;
{
    [self.resultString appendString:_S(_SC(@"@interface ", kColorKeywords), _CL(category.classReference), @" (", _SC(category.name, category.isInsideMainBundle ? kColorClass : kColorOtherClass), @")", nil)];

    NSArray *protocols = category.protocols;
    if (protocols.count) {

        [self.resultString appendString:@"\n<\n"];

        for (CDOCProtocol *protocol in protocols) {
            [self.resultString appendString:_S(@"\t", _PL(protocol), @",\n", nil)];
        }

        [self.resultString deleteCharactersInRange:NSMakeRange(self.resultString.length - 2, 2)];
        [self.resultString appendString:@"\n>"];
    }

    [self.resultString appendString:@"\n"];
}

- (void)didVisitCategory:(CDOCCategory *)category;
{
    [self willEndVisit];
    
    [self.resultString appendString:self.propertiesString];

    if (category.properties.count)
        [self.resultString appendString:@"\n"];

    [self.resultString appendString:self.classMethodsString];
    [self.resultString appendString:self.instanceMethodsString];

    if (self.classMethodsString.length || self.instanceMethodsString.length)
        [self.resultString appendString:@"\n"];

    [self.resultString appendString:_SC(@"@end\n\n", kColorKeywords)];
}

#pragma mark Method

- (void)willVisitOptionalMethods;
{
    self.currentProperties = self.optionalProperties;
    self.currentClassMethods = self.optionalClassMethods;
    self.currentInstanceMethods = self.optionalInstanceMethods;
}

- (void)visitClassMethod:(CDOCMethod *)method;
{
    [self.currentClassMethods addObject:method];
}

- (void)visitInstanceMethod:(CDOCMethod *)method propertyState:(CDVisitorPropertyState *)propertyState;
{
    CDOCProperty *property = [propertyState propertyForAccessor:method.name];
    if (property == nil) {
        [self.currentInstanceMethods addObject:method];
    } else {
        if ([propertyState hasUsedProperty:property] == NO) {
            //NSLog(@"Emitting property %@ triggered by method %@", property.name, method.name);
            [self.currentProperties addObject:property];
            [self visitProperty:property];
            [propertyState useProperty:property];
        } else {
            //NSLog(@"Have already emitted property %@ triggered by method %@", property.name, method.name);
        }
    }
}

#pragma mark Property

- (void)visitRemainingProperties:(CDVisitorPropertyState *)propertyState;
{
    [self.remainingProperties addObjectsFromArray:propertyState.remainingProperties];
}

- (void)visitProperty:(CDOCProperty *)property appendToString:(NSMutableString *)resultString
{
    CDType *parsedType = property.type;
    if (parsedType == nil) {
        if ([property.attributeString hasPrefix:@"T"]) {
            [resultString appendFormat:@"// Error parsing type for property %@:\n", property.name];
            [resultString appendFormat:@"// Property attributes: %@\n\n", property.attributeString];
        } else {
            [resultString appendFormat:@"// Error: Property attributes should begin with the type ('T') attribute, property name: %@\n", property.name];
            [resultString appendFormat:@"// Property attributes: %@\n\n", property.attributeString];
        }
    } else {
        [self _visitProperty:property parsedType:parsedType attributes:property.attributes appendToString:resultString];
    }
}

- (void)_visitProperty:(CDOCProperty *)property parsedType:(CDType *)parsedType attributes:(NSArray *)attrs appendToString:(NSMutableString *)resultString
{
    NSString *backingVar = nil;
    BOOL isDynamic = NO;

    NSMutableArray *alist = [[NSMutableArray alloc] init];
    NSMutableArray *unknownAttrs = [[NSMutableArray alloc] init];

    // objc_v2_encode_prop_attr() in gcc/objc/objc-act.c

    for (NSString *attr in attrs) {
        if ([attr hasPrefix:@"T"]) {
            if (debug) NSLog(@"Warning: Property attribute 'T' should occur only occur at the beginning");
        } else if ([attr hasPrefix:@"N"]) {
            [alist addObject:@"nonatomic"];
        } else if ([attr hasPrefix:@"R"]) {
            [alist addObject:@"readonly"];
        } else if ([attr hasPrefix:@"C"]) {
            [alist addObject:@"copy"];
        } else if ([attr hasPrefix:@"&"]) {
            [alist addObject:@"strong"];
        } else if ([attr hasPrefix:@"W"]) {
            [alist addObject:@"weak"];
        } else if ([attr hasPrefix:@"G"]) {
            [alist addObject:_S(@"getter", _SC(_SF(@"=%@", [attr substringFromIndex:1]), @"black"), nil)];
        } else if ([attr hasPrefix:@"S"]) {
            [alist addObject:_S(@"setter", _SC(_SF(@"=%@", [attr substringFromIndex:1]), @"black"), nil)];
        } else if ([attr hasPrefix:@"V"]) {
            backingVar = [attr substringFromIndex:1];
        } else if ([attr hasPrefix:@"D"]) {
            isDynamic = YES;
        } else {
            if (debug) NSLog(@"Warning: Unknown property attribute '%@'", attr);
            [unknownAttrs addObject:attr];
        }
    }

    NSMutableString *string = [[NSMutableString alloc] init];
    [string appendString:_SC(@"@property ", kColorKeywords)];
    if (alist.count) {
        [string appendString:@"("];
        for (NSString *attr in alist) {
            [string appendString:_SC(attr, kColorKeywords)];
            [string appendString:@", "];
        }
        [string deleteCharactersInRange:NSMakeRange(string.length - 2, 2)];
        [string appendString:@") "];
    }

    [resultString appendString:string];

    parsedType.dataController = self.dataController;
    parsedType.isParsing = YES;
    NSString *formattedString = [self.typeController.propertyTypeFormatter formatVariable:property.name type:parsedType];
    parsedType.isParsing = NO;
    [resultString appendFormat:@"%@;", formattedString];

    if (isDynamic) {
        [resultString appendString:_CS(_SF(@" // @dynamic %@;", property.name))];
    } else if (backingVar != nil) {
        if ([backingVar isEqualToString:property.name]) {
            [resultString appendString:_CS(_SF(@" // @synthesize %@;", property.name))];
        } else {
            [resultString appendString:_CS(_SF(@" // @synthesize %@=%@;", property.name, backingVar))];
        }
    }

    [resultString appendString:@"\n"];
    if ([unknownAttrs count] > 0) {
        [resultString appendFormat:@"// Preceding property had unknown attributes: %@\n", [unknownAttrs componentsJoinedByString:@","]];
        if ([property.attributeString length] > 80) {
            [resultString appendFormat:@"// Original attribute string (following type): %@\n\n", property.attributeStringAfterType];
        } else {
            [resultString appendFormat:@"// Original attribute string: %@\n\n", property.attributeString];
        }
    }
}

#pragma mark -

- (void)writeResultToStandardOutput;
{

}

@end
