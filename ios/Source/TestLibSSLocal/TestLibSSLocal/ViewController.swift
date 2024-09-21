//
//  ViewController.swift
//  TestLibSSLocal
//
//  Created by Zhanggy on 20.09.24.
//

import UIKit
import Combine

func fileInDocument(_ name:String) -> String {
    var logPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    logPath.append(component: name)
    return logPath.path()
}

class ViewController: UITableViewController {
    //section 1
    @IBOutlet weak var ssSwithCell: UITableViewCell!
    
    var stateLabel: UILabel {
        ssSwithCell.detailTextLabel!
    }
    var switchView: UISwitch {
        ssSwithCell.accessoryView as! UISwitch
    }
    
    //section 2
    @IBOutlet weak var ssConnectionCell: UITableViewCell!
    
    //section 3
    @IBOutlet weak var urlTextField: UITextField!
    
    @IBOutlet weak var requestButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    //section 4
    @IBOutlet weak var logTextView: UITextView!
    private var cancellables = Set<AnyCancellable>()

    var client:ProxyClient!
    var sslocal:SSLocalManager!
    var logMonitor:FileMonitor!
    var requestTask: URLSessionDataTask?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 创建一个自定义的 Accessory View
        let swich = UISwitch()
        swich.isOn = true
        swich.addTarget(self, action: #selector(switchChanged), for: .touchUpInside)
        self.ssSwithCell.accessoryView = swich
        self.client = ProxyClient(["api.ipify.org":"104.26.12.205"])
        let str = "ss://chacha20-ietf-poly1305:wEBiEvcJeoBflPcTe9KwcG@10.0.0.19:33533/?outline=1"
        let logFile = fileInDocument("sslocal.log")
        self.sslocal = SSLocalManager(config:SSLocalConf.parse(url: str,logPath: logFile)!)
        
        self.sslocal.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateState(state)
            }
            .store(in: &cancellables)
        
        SSLogger.addListener{ str in
            self.appendLog(str)
        }
        
        logMonitor = FileMonitor.init(filePath: logFile){ str in
            self.appendLog(str)
        }
        logMonitor.startMonitoring()
    }
    
    
    @IBAction func doCancelRequest(_ sender: Any) {
        requestTask?.cancel()
        requestTask = nil
    }
    
    @IBAction func doRequest(_ sender: UIButton) throws {
        let urlString = self.urlTextField.text ?? ""
        if urlString.count == 0 {
            return
        }
        guard let url = URL(string: urlString) else {
            appendLog("url:\(urlString) invalid")
            return
        }
        isRequesting(true)
        requestTask = try client.request(url: url) { str in
            self.appendLog(str)
            self.isRequesting(false)
        }
    }
    
    func isRequesting(_ requeting:Bool) {
        self.requestButton.isEnabled = !requeting
        self.cancelButton.isEnabled = requeting
    }
    
    @MainActor
    func updateState(_ state:SSLocalManager.State) {
        stateLabel.text = state.rawValue
        switchView.isEnabled = true
        switch state {
        case .None:
            switchView.isOn = false
        case .Connected:
            switchView.isOn = true
        case .Connecting,.DisConnecting:
            switchView.isEnabled = true
        }
    }
    
    @MainActor
    func appendLog(_ string:String) {
        var string = string;
        if string.last != "\n" {
            string.append("\n")
        }
        self.logTextView.text.append(string)
    }
    
    @objc func switchChanged(){
        
    }
}
 

class ProxyClient {
    let session:URLSession
    let ipAddressConfig:[String:String]
    init(_ cfg:[String:String]) {
        self.session = URLSession.shared
        self.ipAddressConfig = cfg
    }
    
    private func replaceHost(url:URL) throws -> URLRequest {
        
        guard var comp = URLComponents(url: url, resolvingAgainstBaseURL: false),let originHost = comp.host  else {
            throw SSLocalError.common("invalid_url,\(url)")
        }

        guard let ipaddress = self.ipAddressConfig[originHost] else {
            throw SSLocalError.common("invalid_host,no ip registed\(originHost)")
        }
        comp.host = ipaddress
        
        var req = URLRequest(url: comp.url!)
        req.addValue(originHost, forHTTPHeaderField: "Host")
        return req
    }
    
    func request(url:URL,block: @escaping ((String) -> (Void))) throws -> URLSessionDataTask {
        let req = try replaceHost(url: url)
        block("[Req],start:\(url)")
        let task = session.dataTask(with: req) { data, response, error in
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
