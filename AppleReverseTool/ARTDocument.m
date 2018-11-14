//
//  Document.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/9/28.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTDocument.h"
#import "ARTMainWindowController.h"

@interface ARTDocument ()
<NSWindowDelegate>
@property (nonatomic, strong) ARTMainWindowController *windowController;
@end

@implementation ARTDocument

- (void)dealloc
{

}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

+ (BOOL)autosavesInPlace {
    return YES;
}

- (void)makeWindowControllers {
    // Override to return the Storyboard file name of the document.
    if (self.fileURL) {
        ARTMainWindowController *wc = [ARTMainWindowController windowController];
        wc.window.delegate = self;
        [self addWindowController:wc];
        self.windowController = wc;
        wc.fileURL = self.fileURL;
    } else {
        [NSDocumentController.sharedDocumentController removeDocument:self];
    }
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error if you return nil.
    // Alternatively, you could remove this method and override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    [NSException raise:@"UnimplementedMethod" format:@"%@ is unimplemented", NSStringFromSelector(_cmd)];
    return nil;
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError
{
    self.fileURL = url;
    return YES;
}

#pragma mark - NSWindowDelegate

//- (BOOL)windowShouldClose:(NSWindow *)sender
//{
//    [sender orderOut:nil];
//    return NO;
//}

@end
