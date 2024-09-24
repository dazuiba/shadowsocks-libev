//
//  MyWebViewController.swift
//  TestLibSSLocal
//
//  Created by Zhanggy on 24.09.24.
//
//
//  ViewController.swift
//  WiBlaze
//
//  Created by Justin Bush on 2020-07-14.
//  Copyright © 2020 Justin Bush. All rights reserved.
//

import UIKit
import WebKit

let debug = true
struct OpenParam {
    let homeUrl:URL
    let customUserAgent:String
    let appNameForUserAgent:String
}

class MyWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, UITextFieldDelegate, UIScrollViewDelegate {

    // UI Elements
    var webView: WKWebView!                  // Main WebView
    @IBOutlet weak var textField: UITextField!              // URLSearchBar
    @IBOutlet weak var topConstraint: NSLayoutConstraint!   // Top Bar Constraint
    
    // WebView Observers
    var webViewURLObserver: NSKeyValueObservation?          // Observer for URL
    var webViewTitleObserver: NSKeyValueObservation?        // Observer for Page Title
    var webViewProgressObserver: NSKeyValueObservation?     // Observer for Load Progress
    var openParam:OpenParam!
    override func awakeFromNib() {
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initializers
        initWebView()               // Initalize WebView
        widenTextField()            // Set URLSearchBar constraints
        
        /*
        if !Settings.hasLaunchedBefore {
            Settings.setDefaults()
        }
        */
        
        // OBSERVER: WebView URL (Detect Changes)
        webViewURLObserver = webView.observe(\.url, options: .new) { [weak self] webView, change in
            self?.urlDidChange("\(String(describing: change.newValue))") }
        
    }
    
    
    
    
    // MARK:- WebView
    
    func initWebView() {
        let conf = WKWebViewConfiguration()
        conf.applicationNameForUserAgent = openParam.appNameForUserAgent
        webView = WKWebView(frame: CGRectZero, configuration: conf)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.customUserAgent = openParam.customUserAgent            // Set Browser UserAgent
        webView.isInspectable = true
        // WebView Configuration
        webView.scrollView.delegate = self
        webView.scrollView.isScrollEnabled = true                   // Enable Scroll
        webView.scrollView.keyboardDismissMode = .onDrag            // Hide Keyboard on WebView Drag
        view.addSubview(webView)

        webView.translatesAutoresizingMaskIntoConstraints = false
        self.topConstraint = webView.topAnchor.constraint(equalTo: view.topAnchor)

        NSLayoutConstraint.activate([
            topConstraint,
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Load Homepage
        webView.load(URLRequest(url: openParam.homeUrl))
        //progressBar.progress = 0
        //progressBar.alpha = 0
    }
     
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        Debug.log("webView didStartProvisionalNavigation:\(webView.url?.absoluteString ?? "")")
        alignText()
        updateTextField(pretty: false)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        Debug.log("webView didCommit")
        let urlString = webView.url?.absoluteString
        
        alignText()
        updateTextField(pretty: true)
        resize(urlString!)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Debug.log("webView didFinish")
        let urlString = webView.url?.absoluteString
        navigation.description
        alignText()
        updateTextField(pretty: true)
        resize(urlString!)
        
    }
    
    // TODO: Figure out how to resize WebView when facing sites like YouTube
    // The code below fixes the YouTube layout issue, but messes up every website that follows
    func resize(_ url: String) {
        topConstraint.constant = navBarHeight
        /*
        if Site.needsFullScreen(url) {
            topConstraint.constant = navBarHeight
            Debug.log("FullScreen URL: \(Live.fullURL), withHeight: \(navBarHeight)")
        } else {
            topConstraint.constant = 0
            Debug.log("New Constraint: \(topConstraint.constant)")
        }
        */
        
    }
    
    
    
    // MARK:- URL Did Change
    func urlDidChange(_ url: String) {
        Debug.log("URL: \(url)")        // Debug: Print URL to Load
        resize(url)                     // Resize Layout for Specific Domains
    }
    

    // MARK:- Menu Functions
    /// Load homepage in WebView
    func loadHomepage() {
        webView.load(URLRequest(url: openParam.homeUrl))
    }
    /// Reload current WebView URL
    func refresh() {
        webView.reload()
    }
    
    /// Open Action sheet
    func openAction() {
        Debug.log("Open Share Action")
        let items = [webView.url!]
        let actionSheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(actionSheet, animated: true)
    }
    
    
    // MARK:- TextField Handler
    
    func updateTextField(pretty: Bool) {
        alignText() // TEMP: NEEDED?
        let text =  webView.url?.absoluteString ?? "blank"
        textField.text = text
        Debug.log("updateTextField: \(text)")
    }
    
    var firstLoad = true
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        alignText()
        // Case: First Load
        if firstLoad {
            textField.text = ""             // Empty TextField upon first selection
            firstLoad = false               // Set firstLoad to false
        } else {
            updateTextField(pretty: false)  // Set full URL or search query
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        alignText()
        textField.becomeFirstResponder()
        textField.selectAll(nil)
        textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let url = textField.text!
        updateTextField(pretty: false)   // TEMP: NEEDED?
        webView.load(URLRequest(url: URL(string: url)!))
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateTextField(pretty: false) // TEMP: NEEDED?
        hideKeyboard()
    }
    // TextField: Denies entry to non-ASCII characters (ie. emojis)
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if !string.canBeConverted(to: String.Encoding.ascii) { return false }
        return true
    }
    /// Aligns content of TextField based on search or URL
    func alignText() {
        if textField.isEditing {
            textField.textAlignment = .left
        /*
        } else if webView.isLoading && !Query.isSearchTerm {
            textField.textAlignment = .left
        */
        } else {
            textField.textAlignment = .center
        }
    }
    /// Manually hides keyboard
    func hideKeyboard() {
        textField.resignFirstResponder()
        //checkSecureAndUpdate()
    }
    
    
    /// Resizes `UITextField` in `UINavigationBar` to maximum possible width (called on device rotation)
    func widenTextField() {
        var frame: CGRect? = textField?.frame
        frame?.size.width = 10000
        textField?.frame = frame!
    }
    

}


extension UIViewController {

    /**
     *  Height of status bar + navigation bar (if navigation bar exist)
     */
    var navBarHeight: CGFloat {
        return (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0) +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)
    }
}


struct Debug {
    
    static func log(_ text: String) {
        if debug { print(text) }
    }
    
}



struct Query {
    
    static var text = ""
    static var isSearchTerm = true
    static let urlSyntax = [".", "http", "www", ":", "/"]
    
    /// Determines if `query` is a URL or search term
    static func isURL(_ query: String) -> Bool {
        print("Query.isURL query: \(query)")
        /*
        for syntax in urlSyntax {                       // Check if Query contains URL properties
            print("Does \(query) contain \(syntax)")
            if query.contains(syntax) { return true }
        }
        */
        if query.contains("http") || query.contains("www") || query.contains(".") {
            // Detect for search term "http"
            if query.contains("http ") || query.contains("https ") {
                return false
            } else {
                return true
            }
        }
        return false
    }
    /// Adds HTTPS to query if not already present
    static func addHTTP(_ query: String) -> URL {
        if query.contains("http://") || query.contains("https://") {
            return URL(string: query)!
        } else {
            let url = "https://\(query)"
            return URL(string: url)!
        }
    }
    
    /// Takes a search query and returns a loadable URL
    static func getSearchableURL(_ query: String) -> URL {
        let searchBase = "https://www.google.com/search?&q="
        let searchTerm = query.replacingOccurrences(of: " ", with: "%20")
        return URL(string: "\(searchBase)\(searchTerm)") ?? URL(string: searchBase)!
    }
}
