//
//  SSLocalManager.swift
//  TestLibSSLocal
//
//  Created by Zhanggy on 20.09.24.
//

import Foundation
import libsslocal

class SSLocalManager {
    @Published public private(set) var state:State = .None
    private let operationQueue:DispatchQueue
    private let serverRunQueue:DispatchQueue
    public private(set) var config:SSLocalConf!
    static let shared = SSLocalManager()
    
    var lastServerExitCode:Int32?
    
    func start() throws {
        
        try setState(.Connecting)
        operationQueue.async {
            self.serverRunQueue.async {
                self.lastServerExitCode = startServer(self.config,delegate: self)
                logTry{ try self.setState(.None) }
            }
        }
    }
    
    func stop() throws {
        try setState(.DisConnecting)
        operationQueue.async {
            let _ = stopServer()
        }
    }
    
    fileprivate func ssLocalcallback(){
        logTry{ try self.setState(.Connected) }
    }
    
    private func setState(_ to:State) throws {
        
        guard state.canTransTo(to) else {
            throw SSLocalError.common("cannot process: \(state) -> \(to)")
        }
        SSLogger.info("\(state) -> \(to)")
        self.state = to
    }
    
    enum State: String {
        case None
        case Connecting
        case Connected
        case DisConnecting

        func canTransTo(_ to:State) -> Bool{
            switch to {
            case .Connecting:
                return self == .None
            case .DisConnecting:
                return self == .Connected || self == .Connecting
            default:
                return true
            }
        }
    }
    
    public func setConfig(_ config:SSLocalConf){
        self.config = config
    }
    
    private init() {
        operationQueue = DispatchSerialQueue(label: "sslocal.operation")
        serverRunQueue = DispatchSerialQueue(label: "sslocal.server")
    }
}

func stopServer() {
    stop_ss_local_server()
}

func startServer(_ conf:SSLocalConf,delegate:SSLocalManager) -> Int32{
    SSLogger.info("conf:\(conf.confByUrl)")
    let profile = profile_t(
        remote_host: strdup(conf.remoteHost),
        local_addr: strdup("127.0.0.1"),
        method: strdup(conf.method),
        password: strdup(conf.password),
        prefix: strdup(conf.prefix),
        prefixLen: conf.prefix?.count ?? 0,
        remote_port: conf.remotePort,
        local_port: conf.localPort,
        timeout: 300,
        acl: nil,
        log: strdup(conf.logPath),
        fast_open: 0,
        mode: 0,
        mtu: 0,
        mptcp: 0,
        verbose: 1
    )
    
    // 定义回调函数
    let callback: ss_local_callback = { socks_fd, udp_fd, data in
        SSLogger.info("Callback called with socks_fd: \(socks_fd), udp_fd: \(udp_fd)")
        SSLocalManager.shared.ssLocalcallback()
    }
    // 调用 start_ss_local_server_with_callback
    
    let result = start_ss_local_server_with_callback(profile, callback, nil)
    SSLogger.info("start_ss_local_server_with_callback result: \(result)")
    return result
}

 


public struct SSLogger {
    typealias Listener = (String)->(Void)
    private static var listeners = [Listener]()
    static func addListener( _ listener: @escaping Listener){
        listeners.append(listener)
    }
    
    static func info(_ str:String) {
        print(str)
        listeners.forEach {
            $0(str)
        }
    }
    private init(){
        
    }
}

struct SSLocalConf :Codable {
    let remoteHost:String
    let remotePort:Int32
    let method:String
    let password:String
    let prefix:String?
    var localPort:Int32
    let logPath:String
    static func parse(url:String, localPort:Int32 = 10086, logPath:String) -> Self? {
        guard let url = URL(string: url) else { return nil }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let user = components?.user ?? ""
        let pass = components?.password ?? ""
        let host = components?.host ?? ""
        let port = components?.port ?? 0
        let prefix = components?.query(forKey: "prefix")
        return SSLocalConf(
            remoteHost: host,
            remotePort: Int32(port),
            method: user,
            password: pass,
            prefix: prefix,
            localPort: localPort, // 默认本地端口
            logPath: logPath // 默认日志路径
        )
    }
    
    var confByUrl: String {
        return "ss://\(method):\(password)@\(remoteHost):\(remotePort)/?prefix=\(prefix ?? "")"
    }
}


extension URLComponents {
    func query(forKey:String) -> String? {
        self.queryItems?.first { $0.name == forKey }?.value
    }
}
