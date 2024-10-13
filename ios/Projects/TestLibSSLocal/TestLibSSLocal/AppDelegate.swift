//
//  AppDelegate.swift
//  sslocaltest-iOS
//
//  Created by Zhanggy on 20.09.24.
//

import UIKit
import libsslocal
@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //ss://chacha20-ietf-poly1305:wEBiEvcJeoBflPcTe9KwcG@10.0.0.19:33533/?outline=1
//        let path = "/dev/stdout"//FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path().appending("/ssout.log")
//        
//        let profile = profile_t(
//            remote_host: strdup("10.0.0.19"),
//            local_addr: strdup("127.0.0.1"),
//            method: strdup("chacha20-ietf-poly1305"),
//            password: strdup("wEBiEvcJeoBflPcTe9KwcG"),
//            remote_port: 33533,
//            local_port: 10086,
//            timeout: 300,
//            acl: nil,
//            log: strdup(path),
//            fast_open: 0,
//            mode: 0,
//            mtu: 0,
//            mptcp: 0,
//            verbose: 0
//        )
//        
//        // 定义回调函数
//        let callback: ss_local_callback = { socks_fd, udp_fd, data in
//            print("Callback called with socks_fd: \(socks_fd), udp_fd: \(udp_fd)")
//        }
//        // 调用 start_ss_local_server_with_callback
//        let resultWithCallback = start_ss_local_server_with_callback(profile, callback, nil)
//        print("start_ss_local_server_with_callback result: \(resultWithCallback)")
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

