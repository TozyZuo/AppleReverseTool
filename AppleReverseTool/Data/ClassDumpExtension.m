//
//  ClassDumpExtension.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/3.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ClassDumpExtension.h"
#import "CDTypeLexer.h"
#import "CDTypeParser.h"
#import "CDMethodType.h"
#import "ARTDataController.h"
#import <objc/runtime.h>


NSString *ARTStringCreate(NSString *string, ...)
{
    NSMutableString *ret = [[NSMutableString alloc] init];
    NSString *arg = string;

    va_list ap;
    va_start(ap, string);

    while (arg) {
        [ret appendString:arg];
        arg = va_arg(ap, NSString *);
    }

    va_end(ap);

    return ret;
}

#pragma mark -

@implementation CDOCProtocol (ARTExtension)

- (BOOL)isInsideMainBundle
{
    return [self[ARTAssociatedKeyForSelector(_cmd)] boolValue];
}

- (void)setIsInsideMainBundle:(BOOL)isInsideMainBundle
{
    self[ARTAssociatedKeyForSelector(@selector(isInsideMainBundle))] = @(isInsideMainBundle);
}

@end

@implementation CDOCClass (ARTExtension)

- (id<ARTNode>)superNode
{
    return self[ARTAssociatedKeyForSelector(_cmd)];
}

- (void)setSuperNode:(id<ARTNode>)superNode
{
    [self setWeakObject:superNode forKey:ARTAssociatedKeyForSelector(@selector(superNode))];
}

- (NSArray<id<ARTNode>> *)subNodes
{
    return self.interalSubNodes;
}

- (void)addSubNode:(id<ARTNode>)node
{
    [self.interalSubNodes addObject:node];
}

- (NSMutableArray *)interalSubNodes
{
    NSMutableArray *interalSubNodes = self[ARTAssociatedKeyForSelector(_cmd)];
    if (!interalSubNodes) {
        interalSubNodes = [[NSMutableArray alloc] init];
        self[ARTAssociatedKeyForSelector(_cmd)] = interalSubNodes;
    }
    return interalSubNodes;
}

@end

@interface CDType (ARTExtension_Private)
- (NSString *)formattedStringForMembersAtLevel:(NSUInteger)level formatter:(CDTypeFormatter *)typeFormatter;
- (NSString *)blockSignatureString;
- (NSString *)formattedStringForSimpleType;
@end

TZWarningIgnore(-Wincomplete-implementation)
@implementation CDType (ARTExtension)
TZWarningIgnoreEnd

+ (instancetype)alloc
{
    //    if ([self isMemberOfClass:CDType.class]) {
    if (self == CDType.class) {
        return [ARTType alloc];
    } else {
        return [super alloc];
    }
}

- (BOOL)isInsideMainBundle
{
    return [self[ARTAssociatedKeyForSelector(_cmd)] boolValue];
}

- (void)setIsInsideMainBundle:(BOOL)isInsideMainBundle
{
    self[ARTAssociatedKeyForSelector(@selector(isInsideMainBundle))] = @(isInsideMainBundle);
}

- (void)setIsParsing:(BOOL)isParsing
{

}

- (void)setDataController:(ARTDataController *)dataController
{
    
}

@end

@implementation CDTypeName (ARTExtension)

+ (instancetype)alloc
{
    if (self == CDTypeName.class) {
        return [ARTTypeName alloc];
    } else {
        return [super alloc];
    }
}

@end

@implementation CDTypeController (ARTExtension)
@dynamic structureTable, unionTable;

- (NSString *)structDescriptionWithStructureInfo:(CDStructureInfo *)info
{
    CDTypeFormatter *structDeclarationTypeFormatter = self[@"structDeclarationTypeFormatter"];

    NSString *formattedString = [structDeclarationTypeFormatter formatVariable:nil type:info.type];
    if (formattedString && info.typedefName) {
        return [NSString stringWithFormat:@"typedef %@ %@;\n", formattedString, info.typedefName];
    }
    return formattedString;
}

- (NSString *)structDisplayDescriptionWithStructureInfo:(CDStructureInfo *)info
{
    CDTypeFormatter *structDeclarationTypeFormatter = self[@"structDeclarationTypeFormatter"];

    info.type.isParsing = YES;
    NSString *formattedString = [structDeclarationTypeFormatter formatVariable:nil type:info.type];
    info.type.isParsing = NO;
    if (formattedString && info.typedefName) {
        return _S(_SC(@"typedef", kColorKeywords), _SF(@" %@ %@;\n", formattedString, info.typedefName ? _SC(info.typedefName, kColorOtherClass) : @""), nil);
    }


    return formattedString;
}

@end

@implementation CDStructureTable (ARTExtension)

- (NSDictionary<NSString *,CDStructureInfo *> *)namedStructureInfo
{
    return self[@"phase3_namedStructureInfo"];
}

- (NSDictionary<NSString *,CDStructureInfo *> *)anonStructureInfo
{
    return self[@"phase3_anonStructureInfo"];
}

- (NSDictionary<NSString *,CDStructureInfo *> *)nameExceptions
{
    return self[@"phase3_nameExceptions"];
}

- (NSDictionary<NSString *,CDStructureInfo *> *)anonExceptions
{
    return self[@"phase3_anonExceptions"];
}

@end

#pragma mark -

@implementation ARTTypeController
@dynamic propertyTypeFormatter, ivarTypeFormatter, methodTypeFormatter;

- (id)initWithClassDump:(CDClassDump *)classDump
{
    if (self = [super initWithClassDump:classDump]) {

        ARTTypeFormatter *_propertyTypeFormatter = [[ARTTypeFormatter alloc] init];
        _propertyTypeFormatter.shouldExpand = NO;
        _propertyTypeFormatter.shouldAutoExpand = NO;
        _propertyTypeFormatter.baseLevel = 0;
        _propertyTypeFormatter.typeController = self;
        self[@"propertyTypeFormatter"] = _propertyTypeFormatter;

        ARTTypeFormatter *_ivarTypeFormatter = [[ARTTypeFormatter alloc] init];
        _ivarTypeFormatter.shouldExpand = NO;
        _ivarTypeFormatter.shouldAutoExpand = YES;
        _ivarTypeFormatter.baseLevel = 1;
        _ivarTypeFormatter.typeController = self;
        self[@"ivarTypeFormatter"] = _ivarTypeFormatter;

        ARTTypeFormatter *_methodTypeFormatter = [[ARTTypeFormatter alloc] init];
        _methodTypeFormatter.shouldExpand = NO;
        _methodTypeFormatter.shouldAutoExpand = NO;
        _methodTypeFormatter.baseLevel = 0;
        _methodTypeFormatter.typeController = self;
        self[@"methodTypeFormatter"] = _methodTypeFormatter;

    }
    return self;
}

@end

@implementation ARTTypeFormatter

- (NSString *)_specialCaseVariable:(NSString *)name parsedType:(CDType *)type;
{
    if (type.primitiveType == 'c') {
        if (name == nil)
            return _SC(@"BOOL", kColorKeywords);
        else
            return _S(_SC(@"BOOL", kColorKeywords), @" ", name, nil);
    }

    return nil;
}

- (NSString *)_specialCaseVariable:(NSString *)name type:(NSString *)type;
{
    if ([type isEqual:@"c"]) {
        if (name == nil)
            return _SC(@"BOOL", kColorKeywords);
        else
            return _S(_SC(@"BOOL ", kColorKeywords), name, nil);
//            return [NSString stringWithFormat:@"BOOL %@", name];
#if 0
    } else if ([type isEqual:@"b1"]) {
        if (name == nil)
            return _S(_SC(@"BOOL", kColorKeywords), @" :", _SC(@"1", kColorNumbers), nil);
//            return @"BOOL :1";
        else
            return _S(_SC(@"BOOL ", kColorKeywords), name, @":", _SC(@"1", kColorNumbers), nil);
//            return [NSString stringWithFormat:@"BOOL %@:1", name];
#endif
    }

    return nil;
}

- (NSString *)formatMethodName:(NSString *)methodName typeString:(NSString *)typeString;
{
    CDTypeParser *parser = [[CDTypeParser alloc] initWithString:typeString];

    NSError *error = nil;
    NSArray *methodTypes = [parser parseMethodType:&error];
    if (methodTypes == nil)
        NSLog(@"Warning: Parsing method types failed, %@", methodName);

    if (methodTypes == nil || [methodTypes count] == 0) {
        return nil;
    }

    NSMutableString *resultString = [NSMutableString string];
    {
        NSUInteger count = [methodTypes count];
        NSUInteger index = 0;
        BOOL noMoreTypes = NO;

        CDMethodType *methodType = methodTypes[index];
        [resultString appendString:@"("];
        NSString *specialCase = [self _specialCaseVariable:nil type:methodType.type.bareTypeString];
        if (specialCase != nil) {
            [resultString appendString:specialCase];
        } else {
            CDType *type = methodType.type;
            type.dataController = self.dataController;
            type.isParsing = YES;
            NSString *str = [type formattedString:nil formatter:self level:0];
            type.isParsing = NO;
            if (str != nil)
                [resultString appendFormat:@"%@", str];
        }
        [resultString appendString:@")"];

        index += 3;

        NSScanner *scanner = [[NSScanner alloc] initWithString:methodName];
        while ([scanner isAtEnd] == NO) {
            NSString *str;

            // We can have unnamed paramenters, :::
            if ([scanner scanUpToString:@":" intoString:&str]) {
                //NSLog(@"str += '%@'", str);
                [resultString appendString:str];
            }
            if ([scanner scanString:@":" intoString:NULL]) {
                [resultString appendString:@":"];
                if (index >= count) {
                    noMoreTypes = YES;
                } else {
                    methodType = methodTypes[index];
                    specialCase = [self _specialCaseVariable:nil type:methodType.type.bareTypeString];
                    if (specialCase != nil) {
                        [resultString appendFormat:@"(%@)", specialCase];
                    } else {
                        CDType *type = methodType.type;
                        type.dataController = self.dataController;
                        type.isParsing = YES;
                        NSString *formattedType = [methodType.type formattedString:nil formatter:self level:0];
                        type.isParsing = NO;
                        //if ([[methodType type] isIDType] == NO)
                        [resultString appendFormat:@"(%@)", formattedType];
                    }
                    //[resultString appendFormat:@"fp%@", [methodType offset]];
                    [resultString appendFormat:@"arg%lu", index-2];

                    NSString *ch = [scanner peekCharacter];
                    // if next character is not ':' nor EOS then add space
                    if (ch != nil && [ch isEqual:@":"] == NO)
                        [resultString appendString:@" "];
                    index++;
                }
            }
        }

        if (noMoreTypes) {
            [resultString appendString:@" /* Error: Ran out of types for this method. */"];
        }
    }

    return resultString;
}

@end

@implementation ARTType

- (id)copyWithZone:(NSZone *)zone
{
    ARTType *type = [super copyWithZone:zone];
    type.isInsideMainBundle = self.isInsideMainBundle;
    type.dataController = self.dataController;
    return type;
}

- (void)setIsParsing:(BOOL)isParsing
{
    if (isParsing != _isParsing) {
        _isParsing = isParsing;

        self.subtype.dataController = self.dataController;
        self.subtype.isParsing = isParsing;

        for (CDType *type in self.members) {
            type.dataController = self.dataController;
            type.isParsing = isParsing;
        }

        ((ARTTypeName *)self.typeName).type = self;
        ((ARTTypeName *)self.typeName).dataController = self.dataController;
        ((ARTTypeName *)self.typeName).isParsing = isParsing;
    }
}

- (NSString *)formattedString:(NSString *)previousName formatter:(CDTypeFormatter *)typeFormatter level:(NSUInteger)level;
{
    if (!self.isParsing) {
        return [super formattedString:previousName formatter:typeFormatter level:level];
    }
    NSString *result, *currentName;
    NSString *baseType, *memberString;

    NSString *_variableName = self.variableName;
    NSArray *_protocols = self[@"protocols"];
    CDTypeName *_typeName = self.typeName;
    NSString *_bitfieldSize = self[@"bitfieldSize"];
    NSString *_arraySize = self[@"arraySize"];
    CDType *_subtype = self.subtype;
    NSArray *_members = self.members;

    assert(_variableName == nil || previousName == nil);
    if (_variableName != nil)
        currentName = _variableName;
    else
        currentName = previousName;

    if ([_protocols count])
        [typeFormatter formattingDidReferenceProtocolNames:_protocols];

    switch (self.primitiveType) {
        case T_NAMED_OBJECT: {
            assert(self.typeName != nil);
            [typeFormatter formattingDidReferenceClassName:_typeName.name];

            NSMutableString *typeName = [NSMutableString stringWithString:_CL(_typeName.description)];

            if (_protocols.count) {
                [typeName appendString:@"<"];
                for (NSString *protocol in _protocols) {
                    [typeName appendString:_S(_PL(protocol), @", ", nil)];
                }
                [typeName deleteCharactersInRange:NSMakeRange(typeName.length - 2, 2)];
                [typeName appendString:@">"];
            }

            if (currentName == nil)
                result = [NSString stringWithFormat:@"%@ *", typeName];
            else
                result = [NSString stringWithFormat:@"%@ *%@", typeName, currentName];
            break;
        }
        case '@':
            if (currentName == nil) {
                if (_protocols == nil)
                {
                    result = _SC(@"id", kColorKeywords);
                }
                else
                {
                    NSMutableString *str = [[NSMutableString alloc] init];
                    [str appendString:_S(_SC(@"id", kColorKeywords), @" <", nil)];

                    for (NSString *protocol in _protocols) {
                        [str appendString:_S(_PL(protocol), @", ", nil)];
                    }

                    [str deleteCharactersInRange:NSMakeRange(str.length - 2, 2)];
                    [str appendString:@">"];

                    result = str;
//                    result = [NSString stringWithFormat:@"id <%@>", [_protocols componentsJoinedByString:@", "]];
                }
            } else {

                if (!_protocols)
                {
                    result = _S(_SC(@"id", kColorKeywords), @" ", currentName, nil);
                }
                else
                {
                    NSMutableString *str = [[NSMutableString alloc] init];
                    [str appendString:_S(_SC(@"id", kColorKeywords), @" <", nil)];

                    for (NSString *protocol in _protocols) {
                        [str appendString:_S(_PL(protocol), @", ", nil)];
                    }

                    [str deleteCharactersInRange:NSMakeRange(str.length - 2, 2)];
                    [str appendString:_S(@"> ", currentName, nil)];

                    result = str;
//                    result = [NSString stringWithFormat:@"id <%@> %@", [_protocols componentsJoinedByString:@", "], currentName];
                }
            }
            break;

        case 'b':
            if (currentName == nil) {
                // This actually compiles!
                result = _S(_SC(@"unsigned int ", kColorKeywords), @":", _SC(_bitfieldSize, kColorNumbers), nil);
//                result = [NSString stringWithFormat:@"unsigned int :%@", _bitfieldSize];
            } else
                result = _S(_SC(@"unsigned int ", kColorKeywords), currentName, @":", _SC(_bitfieldSize, kColorNumbers), nil);
//                result = [NSString stringWithFormat:@"unsigned int %@:%@", currentName, _bitfieldSize];
            break;

        case '[':
            result = _S(@"[", _SC(_arraySize, kColorNumbers), @"]", nil);

            if (currentName) {
                result = [currentName stringByAppendingString:result];
            }

            result = [_subtype formattedString:result formatter:typeFormatter level:level];
            break;

        case '(':
            baseType = nil;
            /*if (typeName == nil || [@"?" isEqual:[typeName description]])*/ {
                NSString *typedefName = [typeFormatter typedefNameForStructure:self level:level];
                if (typedefName != nil) {
                    baseType = _SC(_UL(typedefName), kColorOtherClass);
                }
            }

            if (baseType == nil) {
                if (_typeName == nil || [@"?" isEqual:[_typeName description]])
                    baseType = _SC(@"union", kColorKeywords);
                else
                    baseType = _S(_SC(@"union", kColorKeywords), @" ", _SC(_UL(_typeName.description), kColorOtherClass), nil);
//                    baseType = [NSString stringWithFormat:@"union %@", _typeName];

                if ((typeFormatter.shouldAutoExpand && [typeFormatter.typeController shouldExpandType:self] && [_members count] > 0)
                    || (level == 0 && typeFormatter.shouldExpand && [_members count] > 0))
                    memberString = [NSString stringWithFormat:@" {\n%@%@}",
                                    [self formattedStringForMembersAtLevel:level + 1 formatter:typeFormatter],
                                    [NSString spacesIndentedToLevel:typeFormatter.baseLevel + level spacesPerLevel:4]];
                else
                    memberString = @"";

                baseType = [baseType stringByAppendingString:memberString];
            }

            if (currentName == nil /*|| [currentName hasPrefix:@"?"]*/) // Not sure about this
                result = baseType;
            else
                result = [NSString stringWithFormat:@"%@ %@", baseType, currentName];
            break;

        case '{':
            baseType = nil;
            /*if (typeName == nil || [@"?" isEqual:[typeName description]])*/ {
                NSString *typedefName = [typeFormatter typedefNameForStructure:self level:level];
                if (typedefName != nil) {
                    baseType = _SC(_SL(typedefName), kColorOtherClass);
                }
            }
            if (baseType == nil) {
                if (_typeName == nil || [@"?" isEqual:[_typeName description]])
                    baseType = _SC(@"struct", kColorKeywords);
                else
                    baseType = _S(_SC(@"struct", kColorKeywords), @" ", _SC(_SL(_typeName.description), kColorOtherClass), nil);
//                    baseType = [NSString stringWithFormat:@"struct %@", _typeName];

                if ((typeFormatter.shouldAutoExpand && [typeFormatter.typeController shouldExpandType:self] && [_members count] > 0)
                    || (level == 0 && typeFormatter.shouldExpand && [_members count] > 0))
                    memberString = [NSString stringWithFormat:@" {\n%@%@}",
                                    [self formattedStringForMembersAtLevel:level + 1 formatter:typeFormatter],
                                    [NSString spacesIndentedToLevel:typeFormatter.baseLevel + level spacesPerLevel:4]];
                else
                    memberString = @"";

                baseType = [baseType stringByAppendingString:memberString];
            }

            if (currentName == nil /*|| [currentName hasPrefix:@"?"]*/) // Not sure about this
                result = baseType;
            else
                result = [NSString stringWithFormat:@"%@ %@", baseType, currentName];
            break;

        case '^':
            if (currentName == nil)
                result = @"*";
            else
                result = [@"*" stringByAppendingString:currentName];

            if (_subtype != nil && _subtype.primitiveType == '[')
                result = [NSString stringWithFormat:@"(%@)", result];

            result = [_subtype formattedString:result formatter:typeFormatter level:level];
            break;

        case T_FUNCTION_POINTER_TYPE:
            if (currentName == nil)
                result = _SC(@"UnknownFunctionPointerType", kColorKeywords);
            else
                result = _S(_SC(@"UnknownFunctionPointerType ", kColorKeywords), currentName, nil);
//                result = [NSString stringWithFormat:@"CDUnknownFunctionPointerType %@", currentName];
            break;

        case T_BLOCK_TYPE:
            if (self.types) {
                result = [self blockSignatureString];
            } else {
                if (currentName == nil)
                    result = _SC(@"UnknownBlockType", kColorKeywords);
                else
                    result = _S(_SC(@"UnknownBlockType ", kColorKeywords), currentName, nil);
            }
            break;

        case 'j':
        case 'r':
        case 'n':
        case 'N':
        case 'o':
        case 'O':
        case 'R':
        case 'V':
            if (_subtype == nil) {
                if (currentName == nil)
                    result = [self formattedStringForSimpleType];
                else
                    result = [NSString stringWithFormat:@"%@ %@", self.formattedStringForSimpleType, currentName];
            } else
                result = [NSString stringWithFormat:@"%@ %@",
                          self.formattedStringForSimpleType, [_subtype formattedString:currentName formatter:typeFormatter level:level]];
            break;

        default:
            if (currentName == nil)
                result = self.formattedStringForSimpleType;
            else
                result = [NSString stringWithFormat:@"%@ %@", self.formattedStringForSimpleType, currentName];
            break;
    }

    return result;
}

- (NSString *)formattedStringForSimpleType
{
    if (!self.isParsing) {
        return [super formattedStringForSimpleType];
    }
    // Ugly but simple:
    switch (self.primitiveType) {
        case 'c': return _SC(@"char", kColorKeywords);
        case 'i': return _SC(@"int", kColorKeywords);
        case 's': return _SC(@"short", kColorKeywords);
        case 'l': return _SC(@"long", kColorKeywords);
        case 'q': return _SC(@"long long", kColorKeywords);
        case 'C': return _SC(@"unsigned char", kColorKeywords);
        case 'I': return _SC(@"unsigned int", kColorKeywords);
        case 'S': return _SC(@"unsigned short", kColorKeywords);
        case 'L': return _SC(@"unsigned long", kColorKeywords);
        case 'Q': return _SC(@"unsigned long long", kColorKeywords);
        case 'f': return _SC(@"float", kColorKeywords);
        case 'd': return _SC(@"double", kColorKeywords);
        case 'D': return _SC(@"long double", kColorKeywords);
        case 'B': return _SC(@"_Bool", kColorKeywords); // C99 _Bool or C++ bool
        case 'v': return _SC(@"void", kColorKeywords);
        case '*': return _SC(@"STR", kColorKeywords);
        case '#': return _SC(@"Class", kColorKeywords);
        case ':': return _SC(@"SEL", kColorKeywords);
        case '%': return _SC(@"NXAtom", kColorKeywords);
        case '?': return _SC(@"void", kColorKeywords);
            //case '?': return _SC(@"UNKNOWN", kColorKeywords); // For easier regression testing.
        case 'j': return _SC(@"_Complex", kColorKeywords);
        case 'r': return _SC(@"const", kColorKeywords);
        case 'n': return _SC(@"in", kColorKeywords);
        case 'N': return _SC(@"inout", kColorKeywords);
        case 'o': return _SC(@"out", kColorKeywords);
        case 'O': return _SC(@"bycopy", kColorKeywords);
        case 'R': return _SC(@"byref", kColorKeywords);
        case 'V': return _SC(@"oneway", kColorKeywords);
        default:
            break;
    }

    return nil;
}

@end

@implementation ARTTypeName
/*
- (NSString *)description
{
    if (!self.isParsing) {
        return [super description];
    }
    NSString *name = self.name;
    if (name) {
        switch (self.type.primitiveType) {
            case T_NAMED_OBJECT:
                name = _CL(name);
                break;

            default:
                break;
        }
    }
    if ([self.templateTypes count] == 0) {
        return name ?: @"";
    }

    if (self.suffix != nil)
        return [NSString stringWithFormat:@"%@<%@>%@", self.name, [self.templateTypes componentsJoinedByString:@", "], self.suffix];

    return [NSString stringWithFormat:@"%@<%@>", self.name, [self.templateTypes componentsJoinedByString:@", "]];
}
*/
@end
