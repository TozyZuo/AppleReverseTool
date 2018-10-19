//
//  ARTFontManager.h
//  Rcode
//
//  Created by TozyZuo on 2018/10/17.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSFontManager (ART)
- (void)addObserver:(id)observer fontChangeBlock:(void (^)(NSFont *(^updateFontBlock)(NSFont *)))block;
@end

@interface ARTFontManager : ARTManager

@end

NS_ASSUME_NONNULL_END
