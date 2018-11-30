//
//  ARTClassPickerCell.m
//  Rcode
//
//  Created by TozyZuo on 2018/11/29.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTClassPickerCell.h"
#import "ARTConfigManager.h"
#import "ClassDumpExtension.h"

@interface ARTClassPickerCell ()
@end

@implementation ARTClassPickerCell

- (void)initialize
{
    [super initialize];
    self.textView.selectable = NO;
}

- (void)setAClass:(CDOCClass *)aClass
{
    _aClass = aClass;
    self.richTextController.text = aClass.name;
    /*
    if (ARTConfigManager.sharedManager.showBundle) {
        self.richTextController.text = _S(_SC(aClass.name, aClass.isInsideMainBundle ? kColorClass : kColorOtherClass), _SF(@"<font size=%.0f color=%@>[%@]</font>", ceilf(ARTFontManager.sharedFontManager.themeFont.pointSize * .5), kColorBundle, aClass.bundleName), nil);
    } else {
        self.richTextController.text = _SC(aClass.name, aClass.isInsideMainBundle ? kColorClass : kColorOtherClass);
    }
     */
}

@end
