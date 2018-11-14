//
//  AppDelegate.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/9/28.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"ApplePersistenceIgnoreState"])
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ApplePersistenceIgnoreState"];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (NSMenu *)applicationDockMenu:(NSApplication *)sender
{
    NSMutableArray *items = [[NSMutableArray alloc] init];
    for (NSDocument *document in NSDocumentController.sharedDocumentController.documents) {
        if (!document.windowControllers.firstObject.window.visible) {
            [items addObject:[[NSMenuItem alloc] initWithTitle:document.displayName userInfo:document block:^(NSMenuItem * _Nonnull item)
            {
                NSDocument *document = item.representedObject;
                [document.windowControllers.firstObject.window orderFront:nil];
            }]];
        }
    }
    return [NSMenu menuWithTitle:@"" items:items];
}

@end
