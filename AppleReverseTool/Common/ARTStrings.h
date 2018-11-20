//
//  ARTStrings.h
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/3.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NSString *ARTScheme;
extern ARTScheme kSchemeAction;
extern ARTScheme kSchemeClass;
extern ARTScheme kSchemeCategory;
extern ARTScheme kSchemeProtocol;
extern ARTScheme kSchemeStruct;
extern ARTScheme kSchemeUnion;
extern ARTScheme kSchemeBundle;

typedef NSString *ARTSchemeAction;
extern ARTSchemeAction kExpandSubClassAction;
extern ARTSchemeAction kExpandCategoryAction;
extern ARTSchemeAction kExpandSubNodeAction;

typedef NSString *ARTColorType;
extern ARTColorType kColorClass;
extern ARTColorType kColorOtherClass;
extern ARTColorType kColorConnectingLine;
extern ARTColorType kColorExpandButton;
extern ARTColorType kColorStrings;
extern ARTColorType kColorKeywords;
extern ARTColorType kColorComments;
extern ARTColorType kColorNumbers;
extern ARTColorType kColorBundle;
