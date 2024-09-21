//
//  CFHTTPDNSRequestTaskDelegate.h
//  CFHTTPDNSRequest
//
//

#ifndef CFHTTPDNSRequestTaskDelegate_h
#define CFHTTPDNSRequestTaskDelegate_h

#import "CFHTTPDNSRequestTask.h"

/**
 *  CFHTTPDNSRequestTask请求代理
 */
@protocol CFHTTPDNSRequestTaskDelegate <NSObject>

- (void)task:(CFHTTPDNSRequestTask *)task didReceiveResponse:(NSURLResponse *)response cachePolicy:(NSURLCacheStoragePolicy)cachePolicy;
- (void)task:(CFHTTPDNSRequestTask *)task didReceiveRedirection:(NSURLRequest *)request response:(NSURLResponse *)response;
- (void)task:(CFHTTPDNSRequestTask *)task didReceiveData:(NSData *)data;
- (void)task:(CFHTTPDNSRequestTask *)task didCompleteWithError:(NSError *)error;

@end

#endif /* CFHTTPDNSRequestTaskDelegate_h */
