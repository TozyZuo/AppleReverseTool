//
//  ARTTextViewControllerVisitor.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/3.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTTextViewControllerVisitor.h"
#import "ARTDataController.h"
#import "ClassDumpExtension.h"
#import "CDOCClassReference.h"
#import "CDOCMethod.h"
#import "CDOCProperty.h"
#import "CDTypeFormatter.h"
#import "CDVisitorPropertyState.h"
#import "CDOCInstanceVariable.h"
#import "CDTypeLexer.h"
#import <objc/runtime.h>


static BOOL debug = NO;

@interface ARTTextViewControllerVisitor ()
@property (nonatomic, strong) CDTypeController *typeController;
@property (nonatomic,  weak ) ARTDataController *dataController;
@end

@implementation ARTTextViewControllerVisitor

- (id)initWithTypeController:(CDTypeController *)typeController dataController:(nonnull ARTDataController *)dataController
{
    if ((self = [super init])) {
        _resultString = [[NSMutableString alloc] init];
        self.typeController = typeController;
        self.dataController = dataController;
    }

    return self;
}

- (void)willVisitClass:(CDOCClass *)aClass;
{
    if (aClass.isExported == NO)
        [self.resultString appendString:_S(_SC(@"__attribute__", kColorKeywords), @"((visibility(", _SC(@"\"hidden\"", kColorStrings), @")))\n", nil)];
//        [self.resultString appendString:@"__attribute__((visibility(\"hidden\")))\n"];

    [self.resultString appendString:_S(_SC(@"@interface ", kColorKeywords), _SC(aClass.name, aClass.isInsideMainBundle ? kColorClass : kColorOtherClass), nil)];
//    [self.resultString appendFormat:@"@interface %@", aClass.name];

    if (aClass.superClassName != nil)
        [self.resultString appendString:_S(@" : ", _CL(aClass.superClassName), nil)];
//        [self.resultString appendFormat:@" : %@", aClass.superClassName];

    NSArray *protocols = aClass.protocols;
    if (protocols.count) {

        [self.resultString appendString:@"\n<\n"];

        for (CDOCProtocol *protocol in protocols) {
            [self.resultString appendString:_S(@"\t", _PL(protocol.name), @",\n", nil)];
        }

        [self.resultString deleteCharactersInRange:NSMakeRange(self.resultString.length - 2, 2)];
        [self.resultString appendString:@"\n>"];
    }

    [self.resultString appendString:@"\n"];
}

- (void)didVisitClass:(CDOCClass *)aClass;
{
    if (aClass.hasMethods)
        [self.resultString appendString:@"\n"];

    [self.resultString appendString:_S(_SC(@"@end", kColorKeywords), @"\n\n", nil)];
}

- (void)willVisitIvarsOfClass:(CDOCClass *)aClass;
{
    if (aClass.instanceVariables.count) {
        [self.resultString appendString:@"{\n"];
    }
}

- (void)didVisitIvarsOfClass:(CDOCClass *)aClass;
{
    if (aClass.instanceVariables.count) {
        [self.resultString appendString:@"}\n\n"];
    }
}

- (void)willVisitCategory:(CDOCCategory *)category;
{
//    [self.resultString appendFormat:@"@interface %@ (%@)", category.className, category.name];
    [self.resultString appendString:_S(_SC(@"@interface ", kColorKeywords), _CL(category.className), @" (", _SC(category.name, category.isInsideMainBundle ? kColorClass : kColorOtherClass), @")", nil)];

    NSArray *protocols = category.protocols;
    if (protocols.count) {

        [self.resultString appendString:@"\n<\n"];

        for (CDOCProtocol *protocol in protocols) {
            [self.resultString appendString:_S(@"\t", _PL(protocol.name), @",\n", nil)];
        }

        [self.resultString deleteCharactersInRange:NSMakeRange(self.resultString.length - 2, 2)];
        [self.resultString appendString:@"\n>"];
    }

    [self.resultString appendString:@"\n"];
}

- (void)didVisitCategory:(CDOCCategory *)category;
{
    [self.resultString appendString:_SC(@"@end\n\n", kColorKeywords)];
}

- (void)willVisitProtocol:(CDOCProtocol *)protocol;
{
//    [self.resultString appendFormat:@"@protocol %@", protocol.name];
    [self.resultString appendString:_S(_SC(@"@protocol ", kColorKeywords), _SC(protocol.name, protocol.isInsideMainBundle ? kColorClass : kColorOtherClass), nil)];

    NSArray *protocols = protocol.protocols;
    if (protocols.count) {

        [self.resultString appendString:@" <"];

        for (CDOCProtocol *p in protocols) {
            [self. resultString appendString:_S(_PL(p.name), @", ", nil)];
        }

        [self.resultString deleteCharactersInRange:NSMakeRange(self.resultString.length - 2, 2)];
        [self.resultString appendString:@">"];
    }

    [self.resultString appendString:@"\n"];
}

- (void)willVisitOptionalMethods;
{
//    [self.resultString appendString:@"\n@optional\n"];
    [self.resultString appendString:_S(_SC(@"\n@optional\n", kColorKeywords), nil)];
}

- (void)didVisitProtocol:(CDOCProtocol *)protocol;
{
//    [self.resultString appendString:@"@end\n\n"];
    [self.resultString appendString:_S(_SC(@"@end\n\n", kColorKeywords), nil)];
}

- (void)visitClassMethod:(CDOCMethod *)method;
{
    [self.resultString appendString:@"+ "];
    [method appendToString:self.resultString typeController:self.typeController];
    [self.resultString appendString:@"\n"];
}

- (void)visitInstanceMethod:(CDOCMethod *)method propertyState:(CDVisitorPropertyState *)propertyState;
{
    CDOCProperty *property = [propertyState propertyForAccessor:method.name];
    if (property == nil) {
        //NSLog(@"No property for method: %@", method.name);
        [self.resultString appendString:@"- "];
        [method appendToString:self.resultString typeController:self.typeController];
        [self.resultString appendString:@"\n"];
    } else {
        if ([propertyState hasUsedProperty:property] == NO) {
            //NSLog(@"Emitting property %@ triggered by method %@", property.name, method.name);
            [self visitProperty:property];
            [propertyState useProperty:property];
        } else {
            //NSLog(@"Have already emitted property %@ triggered by method %@", property.name, method.name);
        }
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

- (void)visitProperty:(CDOCProperty *)property;
{
    CDType *parsedType = property.type;
    if (parsedType == nil) {
        if ([property.attributeString hasPrefix:@"T"]) {
            [self.resultString appendFormat:@"// Error parsing type for property %@:\n", property.name];
            [self.resultString appendFormat:@"// Property attributes: %@\n\n", property.attributeString];
        } else {
            [self.resultString appendFormat:@"// Error: Property attributes should begin with the type ('T') attribute, property name: %@\n", property.name];
            [self.resultString appendFormat:@"// Property attributes: %@\n\n", property.attributeString];
        }
    } else {
        [self _visitProperty:property parsedType:parsedType attributes:property.attributes];
    }
}

- (void)didVisitPropertiesOfClass:(CDOCClass *)aClass;
{
    if ([aClass.properties count] > 0)
        [self.resultString appendString:@"\n"];
}

- (void)willVisitPropertiesOfCategory:(CDOCCategory *)category;
{
    if ([category.properties count] > 0)
        [self.resultString appendString:@"\n"];
}

- (void)didVisitPropertiesOfCategory:(CDOCCategory *)category;
{
    if ([category.properties count] > 0/* && [aCategory hasMethods]*/)
        [self.resultString appendString:@"\n"];
}

- (void)willVisitPropertiesOfProtocol:(CDOCProtocol *)protocol;
{
    if ([protocol.properties count] > 0)
        [self.resultString appendString:@"\n"];
}

- (void)didVisitPropertiesOfProtocol:(CDOCProtocol *)protocol;
{
    if ([protocol.properties count] > 0 /*&& [aProtocol hasMethods]*/)
        [self.resultString appendString:@"\n"];
}

- (void)visitRemainingProperties:(CDVisitorPropertyState *)propertyState;
{
    NSArray *remaining = propertyState.remainingProperties;

    if ([remaining count] > 0) {
        [self.resultString appendString:@"\n"];
        [self.resultString appendString:_SC(@"// Remaining properties\n", kColorComments)];
        //NSLog(@"Warning: remaining undeclared property count: %u", [remaining count]);
        //NSLog(@"remaining: %@", remaining);
        for (CDOCProperty *property in remaining)
            [self visitProperty:property];
    }
}

#pragma mark -

@synthesize resultString = _resultString;

- (void)writeResultToStandardOutput;
{

}

- (void)_visitProperty:(CDOCProperty *)property parsedType:(CDType *)parsedType attributes:(NSArray *)attrs;
{
    NSString *backingVar = nil;
    BOOL isWeak = NO;
    BOOL isDynamic = NO;

    NSMutableArray *alist = [[NSMutableArray alloc] init];
    NSMutableArray *unknownAttrs = [[NSMutableArray alloc] init];

    // objc_v2_encode_prop_attr() in gcc/objc/objc-act.c

    for (NSString *attr in attrs) {
        if ([attr hasPrefix:@"T"]) {
            if (debug) NSLog(@"Warning: Property attribute 'T' should occur only occur at the beginning");
        } else if ([attr hasPrefix:@"R"]) {
            [alist addObject:@"readonly"];
        } else if ([attr hasPrefix:@"C"]) {
            [alist addObject:@"copy"];
        } else if ([attr hasPrefix:@"&"]) {
//            [alist addObject:@"retain"];
            [alist addObject:@"strong"];
        } else if ([attr hasPrefix:@"G"]) {
            [alist addObject:_S(@"getter", _SC(_SF(@"=%@", [attr substringFromIndex:1]), @"black"), nil)];
//            [alist addObject:[NSString stringWithFormat:@"getter=%@", [attr substringFromIndex:1]]];
        } else if ([attr hasPrefix:@"S"]) {
            [alist addObject:_S(@"setter", _SC(_SF(@"=%@", [attr substringFromIndex:1]), @"black"), nil)];
//            [alist addObject:[NSString stringWithFormat:@"setter=%@", [attr substringFromIndex:1]]];
        } else if ([attr hasPrefix:@"V"]) {
            backingVar = [attr substringFromIndex:1];
        } else if ([attr hasPrefix:@"N"]) {
            [alist addObject:@"nonatomic"];
        } else if ([attr hasPrefix:@"W"]) {
            // @property(assign) __weak NSObject *prop;
            // Only appears with GC.
//            isWeak = YES;
            [alist addObject:@"weak"];
        } else if ([attr hasPrefix:@"P"]) {
            // @property(assign) __strong NSObject *prop;
            // Only appears with GC.
            // This is the default.
            isWeak = NO;
        } else if ([attr hasPrefix:@"D"]) {
            // Dynamic property.  Implementation supplied at runtime.
            // @property int prop; // @dynamic prop;
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
            [string appendString:_S(_SC(attr, kColorKeywords), @", ", nil)];
        }
        [string deleteCharactersInRange:NSMakeRange(string.length - 2, 2)];
        [string appendString:@") "];
    }

//    if (isWeak)
//        [string appendString:@"__weak "];

    [self.resultString appendString:string];

    parsedType.dataController = self.dataController;
    parsedType.isParsing = YES;
    NSString *formattedString = [self.typeController.propertyTypeFormatter formatVariable:property.name type:parsedType];
    parsedType.isParsing = NO;
    [self.resultString appendFormat:@"%@;", formattedString];

    if (isDynamic) {
        [self.resultString appendString:_SC(_SF(@" // @dynamic %@;", property.name), kColorComments)];
//        [self.resultString appendFormat:@" // @dynamic %@;", property.name];
    } else if (backingVar != nil) {
        if ([backingVar isEqualToString:property.name]) {
            [self.resultString appendString:_SC(_SF(@" // @synthesize %@;", property.name), kColorComments)];
//            [self.resultString appendFormat:@" // @synthesize %@;", property.name];
        } else {
            [self.resultString appendString:_SC(_SF(@" // @synthesize %@=%@;", property.name, backingVar), kColorComments)];
//            [self.resultString appendFormat:@" // @synthesize %@=%@;", property.name, backingVar];
        }
    }

    [self.resultString appendString:@"\n"];
    if ([unknownAttrs count] > 0) {
        [self.resultString appendFormat:@"// Preceding property had unknown attributes: %@\n", [unknownAttrs componentsJoinedByString:@","]];
        if ([property.attributeString length] > 80) {
            [self.resultString appendFormat:@"// Original attribute string (following type): %@\n\n", property.attributeStringAfterType];
        } else {
            [self.resultString appendFormat:@"// Original attribute string: %@\n\n", property.attributeString];
        }
    }
}

@end
