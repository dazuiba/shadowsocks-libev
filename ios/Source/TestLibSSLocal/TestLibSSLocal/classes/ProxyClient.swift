//
//  ProxyClient.swift
//  TestLibSSLocal
//
//  Created by Zhanggy on 21.09.24.
//

import UIKit
struct RequestOption {
    let ipConnect:Bool
    let useProxy:Bool
}
class ProxyClient: NSObject,URLSessionDelegate {
    var session:URLSession!
    let ipAddressConfig:[String:String]
    init(config:[String:String],sslocalPort:Int32) {
        self.ipAddressConfig = config
        super.init()

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.protocolClasses = [CFHTTPDNSHTTPProtocol.self];
        self.session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        
//        NSDictionary *proxySettings = @{
//            (NSString *)kCFStreamPropertySOCKSProxyHost: @"your.proxy.host",
//            (NSString *)kCFStreamPropertySOCKSProxyPort: @1080, // 代理端口
//            (NSString *)kCFStreamPropertySOCKSVersion: (NSString *)kCFStreamSocketSOCKSVersion5 // 使用 SOCKS5
//        };

        CFHTTPDNSRequestTask.setProxySetting([kCFStreamPropertySOCKSProxyHost:"127.0.0.1",kCFStreamPropertySOCKSProxyPort:sslocalPort,kCFStreamPropertySOCKSVersion:kCFStreamSocketSOCKSVersion5]);
    }
    
    private func replaceHost(url:URL,_ option:RequestOption) throws -> URLRequest {
        
        guard var comp = URLComponents(url: url, resolvingAgainstBaseURL: false),let originHost = comp.host  else {
            throw SSLocalError.common("invalid_url,\(url)")
        }
        var req = URLRequest(url: url)
        if option.ipConnect {
            guard let ipaddress = self.ipAddressConfig[originHost] else {
                throw SSLocalError.common("invalid_host,no ip registed\(originHost)")
            }
            comp.host = ipaddress
            req = URLRequest(url: comp.url!)
            req.setValue(originHost, forHTTPHeaderField: "X-SSLocal-Real-Host")
        }
        if option.useProxy {
            precondition(option.ipConnect)
            req.setValue("1", forHTTPHeaderField: "X-SSLocal-Proxy")
        }
        return req
    }
    
    func request(url:URL,
                 option:RequestOption,
                 block: @escaping ((String) -> (Void))) throws -> URLSessionDataTask {
        var req = try replaceHost(url: url,option)

        let task = session.dataTask(with: req as URLRequest) { data, response, error in
            if let error = error {
                block("[Req],finish,error: \(error.localizedDescription)")
                return
            }
            guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                block("[Req],finish,Invalid data")
                return
            }
            block("[Req],finish,resp: \(responseString)")

        }
        task.resume()
        return task
    }
    
    func cancel(_ task: URLSessionDataTask) {
        task.cancel()
    }
}
