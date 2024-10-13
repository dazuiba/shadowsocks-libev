//
//  CFHTTPDNSRequestTask.h
//  CFHTTPDNSRequest
//
//

#ifndef CFHTTPDNSRequestTask_h
#define CFHTTPDNSRequestTask_h
#import <Foundation/Foundation.h>
@protocol CFHTTPDNSRequestTaskDelegate;

@interface CFHTTPDNSRequestTask : NSObject

- (CFHTTPDNSRequestTask *)initWithRealURL:(NSURL *)realURL swizzleRequest:(NSURLRequest *)swizzleRequest delegate:(id<CFHTTPDNSRequestTaskDelegate>)delegate;
- (void)startLoading;
- (void)stopLoading;
- (NSString *)getOriginalRequestHost;
- (NSHTTPURLResponse *)getRequestResponse;

+ (void)setProxySetting:(NSDictionary *)proxy;

@end

#endif /* CFHTTPDNSRequestTask_h */
