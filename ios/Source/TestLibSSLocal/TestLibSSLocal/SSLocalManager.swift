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
    private let queue:DispatchQueue
    public private(set) var config:SSLocalConf
    
    func start() throws {
        
        try setState(.Connecting)
        queue.async {
            let _ = startServer(self.config)
        }
    }
    
    func stop() throws {
        try setState(.DisConnecting)
        queue.async {
            let _ = stopServer()
        }
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
            default:
                return true
            }
        }
    }
    init(config:SSLocalConf) {
        queue = DispatchSerialQueue(label: "sslocal")
        self.config = config
    }
}

func stopServer() {
    stop_ss_local_server()
}

func startServer(_ conf:SSLocalConf) -> Bool{
    let profile = profile_t(
        remote_host: strdup(conf.remoteHost),
        local_addr: strdup("127.0.0.1"),
        method: strdup(conf.method),
        password: strdup(conf.password),
        remote_port: conf.remotePort,
        local_port: 10086,
        timeout: 300,
        acl: nil,
        log: strdup(conf.logPath),
        fast_open: 0,
        mode: 0,
        mtu: 0,
        mptcp: 0,
        verbose: 0
    )
    
    // 定义回调函数
    let callback: ss_local_callback = { socks_fd, udp_fd, data in
        SSLogger.info("Callback called with socks_fd: \(socks_fd), udp_fd: \(udp_fd)")
    }
    // 调用 start_ss_local_server_with_callback
    let result = start_ss_local_server_with_callback(profile, callback, nil)
    SSLogger.info("start_ss_local_server_with_callback result: \(result)")
    return result == 0
}

 


public struct SSLogger {
    typealias Listener = (String)->(Void)
    static var listeners = [Listener]()
    static func addListener( _ listener: @escaping Listener){
        listeners.append(listener)
    }
    
    static func info(_ str:String) {
        print(str)
        listeners.forEach {
            $0(str)
        }
    }
}

struct SSLocalConf {
    let remoteHost:String
    let remotePort:Int32
    let method:String
    let password:String
    let localPort:Int32
    let logPath:String
    static func parse(url:String, localPort:Int32 = 10086, logPath:String) -> Self? {
        // ss://chacha20-ietf-poly1305:wEBiEvcJeoBflPcTe9KwcG@10.0.0.19:33533/?outline=1
        guard let url = URL(string: url) else { return nil }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let userInfo = components?.user ?? ""
        let host = components?.host ?? ""
        let port = components?.port ?? 0
        let methodAndPassword = userInfo.split(separator: ":")
        let method = String(methodAndPassword.first ?? "")
        let password = String(methodAndPassword.last ?? "")
        
        return SSLocalConf(
            remoteHost: host,
            remotePort: Int32(port),
            method: method,
            password: password,
            localPort: localPort, // 默认本地端口
            logPath: logPath // 默认日志路径
        )
    }
}


enum SSLocalError : Error {
    case configNotSet
    case common(String)
}
