//
//  ARTFontManager.h
//  Rcode
//
//  Created by TozyZuo on 2018/10/17.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface ARTFontManager : NSFontManager
@property (class, readonly, strong) ARTFontManager *sharedFontManager;
@property (nonatomic, strong) NSFont *themeFont;
- (void)addObserver:(id)observer fontChangeBlock:(void (^)(NSFont *(^updateFontBlock)(NSFont *)))block;
@end

NS_ASSUME_NONNULL_END
