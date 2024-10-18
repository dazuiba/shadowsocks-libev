import XCTest
@testable import SSNet

final class ProxyClientTests: XCTestCase {
    var proxyClient: ProxyClient!
    var mockMetricDelegate: MockMetricDelegate!

    override func setUp() {
        super.setUp()
        let config = ["example.com": "93.184.216.34"]
        proxyClient = ProxyClient(config: config, sslocalPort: 1080)
        mockMetricDelegate = MockMetricDelegate()
        ProxyClient.metric = mockMetricDelegate
    }

    override func tearDown() {
        proxyClient = nil
        mockMetricDelegate = nil
        super.tearDown()
    }

    func testInitialization() {
        XCTAssertNotNil(proxyClient)
        XCTAssertEqual(proxyClient.ipAddressConfig["example.com"], "93.184.216.34")
    }

    func testReplaceHostWithValidHost() throws {
        let url = URL(string: "http://example.com")!
        let option = RequestOption(ipConnect: true, useProxy: false)
        let request = try proxyClient.replaceHost(url: url, option)
        XCTAssertEqual(request.url?.host, "93.184.216.34")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-SSLocal-Real-Host"), "example.com")
    }

    func testReplaceHostWithInvalidHost() {
        let url = URL(string: "http://invalid.com")!
        let option = RequestOption(ipConnect: true, useProxy: false)
        XCTAssertThrowsError(try proxyClient.replaceHost(url: url, option)) { error in
            XCTAssertEqual(error as? SSLocalError, SSLocalError.common("invalid_host,no ip registedinvalid.com"))
        }
    }

    func testRequest() throws {
        let url = URL(string: "http://example.com")!
        let option = RequestOption(ipConnect: false, useProxy: false)
        let expectation = self.expectation(description: "Request should complete")
        
        let task = try proxyClient.request(url: url, option: option) { response in
            XCTAssertTrue(response.contains("[Req],finish"))
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertNotNil(task)
    }

    func testCancel() throws {
        let url = URL(string: "http://example.com")!
        let option = RequestOption(ipConnect: false, useProxy: false)
        let task = try proxyClient.request(url: url, option: option) { _ in }
        proxyClient.cancel(task)
        XCTAssertEqual(task.state, URLSessionTask.State.canceling)
    }

    func testUrlSessionDidFinishCollectingMetrics() {
        let session = URLSession(configuration: .default)
        let task = URLSessionDataTask()
        let metrics = URLSessionTaskMetrics()
        
        proxyClient.urlSession(session, task: task, didFinishCollecting: metrics)
        
        XCTAssertTrue(mockMetricDelegate.didCollectMetrics)
    }
}

class MockMetricDelegate: MetricDelegate {
    var didCollectMetrics = false
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        didCollectMetrics = true
    }
}
