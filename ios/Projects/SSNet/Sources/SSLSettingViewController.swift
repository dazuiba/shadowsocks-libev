//
//  ViewController.swift
//  TestLibSSLocal
//
//  Created by Zhanggy on 20.09.24.
//

import UIKit
import Combine
let storyboard = UIStoryboard(name: "Main", bundle: nil)
@objc(SSLSettingViewController)
public class SSLSettingViewController: UITableViewController {
    //section 1
    @IBOutlet weak var ssSwithCell: UITableViewCell!
    
    var stateLabel: UILabel {
        ssSwithCell.detailTextLabel!
    }
    var switchControl: UISwitch {
        ssSwithCell.accessoryView as! UISwitch
    }
    
    @IBOutlet weak var prefixSwitch: UISwitch!
    //section 2
    @IBOutlet weak var ssConnectionCell: UITableViewCell!
    
    var connectionUrlLabel: UILabel {
        ssConnectionCell.textLabel!
    }
    
    var connectionDetailA: UILabel {
        ssConnectionCell.detailTextLabel!
    }
    
    //section 3
    @IBOutlet weak var urlTextField: UITextField!
    
    @IBOutlet weak var requestButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    //section 4
    @IBOutlet weak var logTextView: UITextView!
    private var cancellables = Set<AnyCancellable>()

    @IBOutlet weak var useSocksProxy: UISwitch!
    @IBOutlet weak var useIpConnect: UISwitch!
    
    var sslocal = SSLocalManager.shared
    var logMonitor:FileMonitor!
    var requestTask: URLSessionDataTask?
    @objc func pushWebVC() {
//        let myweb = storyboard?.instantiateViewController(withIdentifier: "MyWebViewController") as! MyWebViewController
////        let url = "https://www.youtubekits.com",
//        let url = "https://www.google.com"
//        myweb.openParam = .init(homeUrl: URL(string: url)!,
////                              customUserAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko)",
//                                customUserAgent: "Mozilla/5.0 (iPad; CPU OS 6_0 like Mac OS X   ) AppleWebKit/537.36 (KHTML, like Gecko)",
//
//                                appNameForUserAgent: "Chrome/129.0.0.0")
//        self.navigationController?.pushViewController(myweb, animated: true)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.navigationItem.rightBarButtonItem = .init(title: "open url", style: .plain, target: self, action: #selector(pushWebVC))
        // 创建一个自定义的 Accessory View
        let swich = UISwitch()
        swich.isOn = true
        swich.addTarget(self, action: #selector(switchChanged), for: .touchUpInside)
        self.ssSwithCell.accessoryView = swich

        let logFile = fileInDocument("sslocal.log",createIfNotExsit: true)
        self.connectionUrlLabel.text = "\(sslocal.config.remoteHost):\(sslocal.config.remotePort)"
        self.urlTextField.text = "https://api.ipify.org/?format=json"
        switchControl.isOn = true

        self.sslocal.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                Task { @MainActor in
                    self?.updateState(state)
                }
            }
            .store(in: &cancellables)
        
        SSLogger.addListener{ str in
            Task { @MainActor in
                self.appendLog(str)
            }
        }
        
        logMonitor = FileMonitor.init(filePath: logFile){ str in
            Task { @MainActor in
                self.appendLog(str)
            }
        }
        logMonitor.startMonitoring()
        logTextView.text = nil
    }
    
    
    @objc  @IBAction func doCancelRequest(_ sender: Any) {
        requestTask?.cancel()
        requestTask = nil
    }

    @objc @IBAction func doRequest(_ sender: UIButton) {
        let urlString = self.urlTextField.text ?? ""
        if urlString.count == 0 {
            return
        }
        guard let url = URL(string: urlString) else {
            appendLog("url:\(urlString) invalid")
            return
        }
        isRequesting(true)
        let req = URLRequest(url: url)
        self.requestTask = ProxyClient.shared.session.dataTask(with: req as URLRequest) { data, response, error in
                var log:String! = nil
                 if let error {
                     log = "[Req],finish,error: \(error.localizedDescription)"
                 } else if let data,let responseString = String(data: data, encoding: .utf8) {
                     log = "[Req],finish,resp: \(responseString)"
                 } else {
                     log = "[Req],finish,Invalid data"
                 }
                Task { @MainActor in
                    self.appendLog(log)
                    self.isRequesting(false)
                }
             }
        self.requestTask!.resume()
    }
    
    func isRequesting(_ requeting:Bool) {
        self.requestButton.isEnabled = !requeting
        self.cancelButton.isEnabled = requeting
    }
    
    @MainActor
    func updateState(_ state:SSLocalManager.State) {
        stateLabel.text = state.rawValue
        switchControl.isEnabled = true
        switchControl.isOn = true

        switch state {
        case .None:
            switchControl.isOn = false
        case .Connected:
            break
        case .Connecting:
            switchControl.isEnabled = false
        case .DisConnecting:
            switchControl.isEnabled = true
        }
    }
    
    @MainActor
    func appendLog(_ string:String) {
        if !Thread.isMainThread {
            print("not_main")
        }
        var string = string;
        if string.last != "\n" {
            string.append("\n")
        }
        self.logTextView.text.append(string)
    }
    
    @objc func switchChanged(_ sender:UISwitch){
        appendLog("switch:\(sender.isOn)")
        do {
            if sender.isOn {
                try self.sslocal.start()
            } else {
                try self.sslocal.stop()
            }
        } catch {
            appendLog("switch:\(error)")
        }
    }
    
    @IBAction func cleanLog(_ sender: Any) {
        self.logTextView.text = nil
    }
    
    // 实现 UITableViewDelegate 方法
    public override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        // 处理附件视图点击事件
        let cell = tableView.cellForRow(at: indexPath)
        if cell == self.ssConnectionCell {
            //show detail
            let config = self.sslocal.config
            let str = printObjectAsJSON(obj: config, format: true)
            appendLog("config: \(str)")
        }
    }
}
