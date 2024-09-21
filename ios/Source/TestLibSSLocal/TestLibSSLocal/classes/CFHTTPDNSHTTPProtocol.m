//
//  CFHTTPDNSHTTPProtocol.m
//  CFHTTPDNSRequest
//
//

#import <Foundation/Foundation.h>
#import <arpa/inet.h>
#import "CFHTTPDNSHTTPProtocol.h"
#import "CFHTTPDNSRequestTaskDelegate.h"

/**
 *  此文件用户谨慎使用，demo仅提供演示案例，用户请根据自身业务自行改写本文件
 *  本示例拦截HTTPS请求，使用HTTPDNS进行域名解析，基于CFNetwork发送HTTPS请求，并适配SNI配置；
 *  若有HTTP请求，或重定向时有HTTP请求，需要另注册其他NSURLProtocol来处理或者走系统原生处理逻辑。
 *
 *  NSURLProtocol API描述参考：https://developer.apple.com/reference/foundation/nsurlprotocol
 *  尽可能拦截少量网络请求，尽量避免直接基于CFNetwork发送HTTP/HTTPS请求。
 */

static NSString *recursiveRequestFlagProperty = @"com.aliyun.httpdns";
static NSString *realHostFlagProperty = @"realHost";

@interface CFHTTPDNSHTTPProtocol () <CFHTTPDNSRequestTaskDelegate>

// 基于CFNetwork发送HTTPS请求的Task
@property (atomic, strong) CFHTTPDNSRequestTask *task;
// 记录请求开始时间
@property (atomic, assign) NSTimeInterval startTime;

@end

@implementation CFHTTPDNSHTTPProtocol

#pragma mark NSURLProtocl API

/**
 *  是否拦截处理指定的请求
 *
 *  @param request 指定的请求
 *
 *  @return YES:拦截处理，NO:不拦截处理
 */
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    BOOL shouldAccept = YES;
    
    if (request == nil || request.URL == nil || request.URL.scheme == nil ||
        ![request.URL.scheme isEqualToString:@"https"] ||
        [NSURLProtocol propertyForKey:recursiveRequestFlagProperty inRequest:request] != nil) {
        shouldAccept = NO;
    }
    
    if (shouldAccept) {
        shouldAccept = false;
        if([self.class isIPAddress:request.URL.host]) {
            NSString *realHost = [request valueForHTTPHeaderField:@"X-SSLocal-Real-Host"];
            if(realHost != nil) {
                shouldAccept = true;
            }
        }
    }
    
    
    if (shouldAccept) {
        NSLog(@"Accept request: %@.", request);
    } else {
        NSLog(@"Decline request: %@.", request);
    }
    
    return shouldAccept;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

/**
 *  开始加载请求
 */
- (void)startLoading {
    NSLog(@"startLoading");
    NSMutableURLRequest *recursiveRequest = [[self request] mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:recursiveRequestFlagProperty inRequest:recursiveRequest];
    self.startTime = [NSDate timeIntervalSinceReferenceDate];
    // 构造CFHTTPDNSRequestTask，基于CFNetwork发送HTTPS请求
//    NSURLRequest *swizzleRequest = [self httpdnsResolve:recursiveRequest];
    NSString *host = [recursiveRequest valueForHTTPHeaderField:@"X-SSLocal-Real-Host"];
    NSURL *realURL = recursiveRequest.URL;
    if (host) {
        NSURLComponents *comp = [NSURLComponents componentsWithURL:recursiveRequest.URL resolvingAgainstBaseURL:false];
        comp.host = host;
        realURL = comp.URL;
        
        [recursiveRequest setValue:host forHTTPHeaderField:@"Host"];
    }
    self.task = [[CFHTTPDNSRequestTask alloc] initWithRealURL:realURL swizzleRequest:recursiveRequest delegate:self];
    if (self.task) {
        [self.task startLoading];
    }
}

/**
 *  停止加载请求
 */
- (void)stopLoading {
    NSLog(@"stopLoading");
    NSLog(@"[%@] stop loading, elapsed %.1f seconds.", self.request, [NSDate timeIntervalSinceReferenceDate] - self.startTime);
    if (self.task) {
        [self.task stopLoading];
        self.task = nil;
    }
}

#pragma mark CFHTTPDNSRequestTask Protocol

- (void)task:(CFHTTPDNSRequestTask *)task didReceiveRedirection:(NSURLRequest *)request response:(NSURLResponse *)response {
    NSLog(@"Redirect from [%@] to [%@].", response.URL, request.URL);
    NSMutableURLRequest *mRequest = [request mutableCopy];
    [NSURLProtocol removePropertyForKey:recursiveRequestFlagProperty inRequest:mRequest];
    NSURLResponse *cResponse = [response copy];
    [task stopLoading];
    /*
     *  交由NSProtocolClient处理重定向请求
     *  request: 重定向后的request
     *  redirectResponse: 原请求返回的Response
     */
    [self.client URLProtocol:self wasRedirectedToRequest:mRequest redirectResponse:cResponse];
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)task:(CFHTTPDNSRequestTask *)task didReceiveResponse:(NSURLResponse *)response cachePolicy:(NSURLCacheStoragePolicy)cachePolicy {
    NSLog(@"Did receive response: %@", response);
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:cachePolicy];
}

- (void)task:(CFHTTPDNSRequestTask *)task didReceiveData:(NSData *)data {
    NSLog(@"Did receive data.");
    [self.client URLProtocol:self didLoadData:data];
}

- (void)task:(CFHTTPDNSRequestTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        NSLog(@"Did complete with error, %@.", error);
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        NSLog(@"Did complete success.");
        [self.client URLProtocolDidFinishLoading:self];
    }
}

/**
 *  DNS解析域名，重新构造请求
 *  若原始请求基于IP地址，无需做域名解析直接返回
 */
//- (NSURLRequest *)httpdnsResolve:(NSURLRequest *)request {
//    NSMutableURLRequest *swizzleRequest;
//    NSLog(@"DNS start resolve URL: %@", request.URL.absoluteString);
//    NSURL *originURL = request.URL;
//    NSString *originURLStr = originURL.absoluteString;
//    swizzleRequest = [request mutableCopy];
//    //根据您的需求和使用习惯选择相应解析方法
//    NSString *ip = [[DNSResolver share] getIpsByCacheWithDomain:originURL.host andExpiredIPEnabled:YES].firstObject;
//    
//    // 通过HTTPDNS获取IP成功，进行URL替换和HOST头设置
//    if (ip) {
//        NSLog(@"Get IP from DNS Successfully!");
//        NSRange hostFirstRange = [originURLStr rangeOfString:originURL.host];
//        if (NSNotFound != hostFirstRange.location) {
//            NSString *newUrl = [originURLStr stringByReplacingCharactersInRange:hostFirstRange withString:ip];
//            swizzleRequest.URL = [NSURL URLWithString:newUrl];
//            [swizzleRequest setValue:originURL.host forHTTPHeaderField:@"host"];
//        }
//    } else {
//        // 没有获取到域名解析结果
//        return request;
//    }
//    return swizzleRequest;
//}

/**
 *  判断输入是否为IP地址
 */
+ (BOOL)isIPAddress:(NSString *)str {
    if (!str) {
        return NO;
    }
    int success;
    struct in_addr dst;
    struct in6_addr dst6;
    const char *utf8 = [str UTF8String];
    // check IPv4 address
    success = inet_pton(AF_INET, utf8, &(dst.s_addr));
    if (!success) {
        // check IPv6 address
        success = inet_pton(AF_INET6, utf8, &dst6);
    }
    return success;
}

@end
