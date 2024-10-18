/**
 * Copyright (c) Tencent. All rights reserved.
 */
#import <Foundation/Foundation.h>

@protocol SSNetURLProtocolHelper <NSObject>
- (BOOL)shouldProcessDomain:(NSString *)domain;
- (NSArray *) getHostByName:(NSString *) domain;

- (NSDictionary * __nullable )connectionProxyDictionaryOrNil;
@end

@interface SSNetURLProtocol : NSURLProtocol

+ (void)setProtocolHelper:(id<SSNetURLProtocolHelper>)helper;
@end
