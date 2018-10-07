//
//  ARTWindowController.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/9/30.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTWindowController.h"

@interface ARTWindowController ()

@end

@implementation ARTWindowController

+ (instancetype)windowController
{
    return [[self alloc] initWithWindowNibName:NSStringFromClass(self)];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
