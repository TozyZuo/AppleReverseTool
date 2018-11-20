//
//  ARTManager.m
//  Rcode
//
//  Created by TozyZuo on 2018/10/17.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTManager.h"

@implementation ARTManager

+ (instancetype)sharedManager
{
    return [self sharedInstance];
}

@end

@implementation ARTManagerController

- (id)selection
{
    id manager = ((id)self.class)[ARTAssociatedKeyForSelector(_cmd)];
    if (!manager) {
        NSString *classString = NSStringFromClass(self.class);
        manager = [NSClassFromString([classString substringToIndex:classString.length - 10/*Controller*/]) sharedManager];
        ((id)self.class)[ARTAssociatedKeyForSelector(_cmd)] = manager;
    }
    return manager;
}

@end
