//
//  ViewController.swift
//  TestLibSSLocal
//
//  Created by Zhanggy on 20.09.24.
//

import UIKit
import Combine

class ViewController: UITableViewController {
    //section 1
    @IBOutlet weak var ssSwithCell: UITableViewCell!
    
    var stateLabel: UILabel {
        ssSwithCell.detailTextLabel!
    }
    var switchControl: UISwitch {
        ssSwithCell.accessoryView as! UISwitch
    }
    
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
    
    var client:ProxyClient!
    var sslocal = SSLocalManager.shared
    var logMonitor:FileMonitor!
    var requestTask: URLSessionDataTask?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        
        // 创建一个自定义的 Accessory View
        let swich = UISwitch()
        swich.isOn = true
        swich.addTarget(self, action: #selector(switchChanged), for: .touchUpInside)
        self.ssSwithCell.accessoryView = swich

        let str = "ss://chacha20-ietf-poly1305:wEBiEvcJeoBflPcTe9KwcG@10.0.0.19:33533/?outline=1"
//        let str = "ss://chacha20-ietf-poly1305:wEBiEvcJeoBflPcTe9KwcG@127.0.0.1:1082/?outline=1"
        let logFile = fileInDocument("sslocal.log",createIfNotExsit: true)
        let ssconf = SSLocalConf.parse(url: str, localPort:1081 ,logPath: logFile)!
        sslocal.setConfig(ssconf)

        self.client = ProxyClient(config: ["api.ipify.org":"104.26.13.205"],sslocalPort: ssconf.localPort)

        self.connectionUrlLabel.text = "\(sslocal.config.remoteHost):\(sslocal.config.remotePort)"
        self.urlTextField.text = "https://api.ipify.org/?format=json"
        
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
        switchControl.isOn = true
        switchChanged(switchControl)
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
        let opt = RequestOption(ipConnect: self.useIpConnect.isOn, useProxy: self.useSocksProxy.isOn)
        self.requestTask = logTry{
            try client.request(url: url,option: opt, block: { str in
                Task { @MainActor in
                    self.appendLog(str)
                    self.isRequesting(false)
                }
            })
        }
        
//        self.requestTask = client.request(with: url) { str, err in
//            Task { @MainActor in
//                self.appendLog(str ?? "err:\(String(describing: err))")
//                self.isRequesting(false)
//            }
//
//        }
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
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
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
