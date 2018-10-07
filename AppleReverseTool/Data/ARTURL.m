//
//  ARTURL.m
//  AppleReverseTool
//
//  Created by TozyZuo on 2018/10/6.
//  Copyright © 2018年 TozyZuo. All rights reserved.
//

#import "ARTURL.h"

@interface ARTURL ()
@property (nonatomic, strong) NSString *string;
@end

@implementation ARTURL
@synthesize scheme = _scheme, host = _host, path = _path;

- (instancetype)initWithString:(NSString *)string
{
    self = [super init];
    if (self) {
        self.string = string;
    }
    return self;
}

- (NSString *)scheme
{
    if (!_scheme) {
        _scheme = [self.string componentsSeparatedByString:@"://"].firstObject;
    }
    return _scheme;
}

- (NSString *)host
{
    if (!_host) {
        _host = [[self.string componentsSeparatedByString:@"://"].lastObject componentsSeparatedByString:@"/"].firstObject;
    }
    return _host;
}

- (NSString *)path
{
    if (!_path) {
        _path = [[self.string componentsSeparatedByString:self.host].lastObject substringFromIndex:1];
    }
    return _path;
}
@end
