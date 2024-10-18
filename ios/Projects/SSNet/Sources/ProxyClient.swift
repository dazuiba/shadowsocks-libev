//
//  ProxyClient.swift
//  TestLibSSLocal
//
//  Created by Zhanggy on 21.09.24.
//

import UIKit
import MSDKDns_C11
import SSNetOC
public protocol MetricDelegate{
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didFinishCollecting metrics: URLSessionTaskMetrics);
}
struct RequestOption {
    let ipConnect:Bool
    let useProxy:Bool
}
public class ProxyClient: NSObject,URLSessionDelegate, URLSessionTaskDelegate, SSNetURLProtocolHelper {
    public static var preResolvedDomains = [String]()
    public static let shared = ProxyClient()
    public func connectionProxyDictionaryOrNil() -> [AnyHashable : Any]? {
        let port = SSLocalManager.shared.config.localPort
        return [
            kCFStreamPropertySOCKSProxyHost as String: "127.0.0.1",
            kCFStreamPropertySOCKSProxyPort as String: port,
            kCFStreamPropertySOCKSVersion as String: kCFStreamSocketSOCKSVersion5 as String
        ]
    }
    
    public func shouldProcessDomain(_ domain: String!) -> Bool {
        return true
    }
    
    public func getHostByName(_ domain: String!) -> [Any]! {
        self.msdkDns.wgGetHost(byName: domain)
    }
    
    public private(set) var session:URLSession!
    private var msdkDns: MSDKDns!
    public static var metric:MetricDelegate?
    private override init() {
        super.init()
        SSNetURLProtocol.setProtocolHelper(self)
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.protocolClasses = [SSNetURLProtocol.self]
        self.session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        self.msdkDns = MSDKDns.sharedInstance() as? MSDKDns;
        self.msdkDns.initConfig(with: [
            "debug": true,
            "dnsId": "99615",
            "dnsKey": "967208304",
            "encryptType": 2, // 0 -> des，1 -> aes，2 -> https
        ]);
        self.msdkDns.wgSetPreResolvedDomains(Self.preResolvedDomains)
    }
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics){
        Self.metric?.urlSession(session, task: task, didFinishCollecting: metrics)
    }
}
