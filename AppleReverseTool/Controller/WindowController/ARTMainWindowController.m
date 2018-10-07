//
//  ARTMainWindowController.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/9/30.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTMainWindowController.h"
#import "ARTMainViewController.h"

@interface ARTMainWindowController ()

@end

@implementation ARTMainWindowController

+ (instancetype)windowController
{
    return [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"ARTMainWindowController"];
}

- (void)awakeFromNib
{

}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)setFileURL:(NSURL *)fileURL
{
    if (!_fileURL && fileURL) {
        _fileURL = fileURL;
        ((ARTMainViewController *)self.contentViewController).fileURL = fileURL;
    }
}

@end
