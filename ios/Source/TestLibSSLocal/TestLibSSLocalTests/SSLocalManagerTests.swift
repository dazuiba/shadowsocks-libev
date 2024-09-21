import XCTest
@testable import TestLibSSLocal

final class SSLocalManagerTests: XCTestCase {

    func testSSLocalConfParse() throws {
        let url = "ss://chacha20-ietf-poly1305:wEBiEvcJeoBflPcTe9KwcG@10.0.0.19:33533/?outline=1"
        let conf = try XCTUnwrap(SSLocalConf.parse(url: url,logPath: "/dev/stdout"))
        
        XCTAssertEqual(conf.remoteHost, "10.0.0.19")
        XCTAssertEqual(conf.remotePort, 33533)
        XCTAssertEqual(conf.method, "chacha20-ietf-poly1305")
        XCTAssertEqual(conf.password, "wEBiEvcJeoBflPcTe9KwcG")
        XCTAssertEqual(conf.localPort, 1080)
        XCTAssertEqual(conf.logPath, "/var/log/sslocal.log")
    }

    func testSSLocalManagerStart() throws {
        let conf = SSLocalConf(remoteHost: "10.0.0.19", remotePort: 33533, method: "chacha20-ietf-poly1305", password: "password", localPort: 1080, logPath: "/var/log/sslocal.log")
        let manager = SSLocalManager(config: conf)
        
        XCTAssertNoThrow(try manager.start())
    }

    func testSSLocalManagerStop() throws {
        let conf = SSLocalConf(remoteHost: "10.0.0.19", remotePort: 33533, method: "chacha20-ietf-poly1305", password: "password", localPort: 1080, logPath: "/var/log/sslocal.log")
        let manager = SSLocalManager(config: conf)
        
        XCTAssertNoThrow(try manager.stop())
    }

    func testSSLocalManagerStateTransitions() throws {
        let conf = SSLocalConf(remoteHost: "10.0.0.19", remotePort: 33533, method: "chacha20-ietf-poly1305", password: "password", localPort: 1080, logPath: "/var/log/sslocal.log")
        let manager = SSLocalManager(config: conf)
        
        XCTAssertNoThrow(try manager.start())
        XCTAssertNoThrow(try manager.stop())
    }

    func testSSLogger() {
        var logMessages = [String]()
        SSLogger.addListener { message in
            logMessages.append(message)
        }
        
        SSLogger.info("Test message")
        
        XCTAssertEqual(logMessages.count, 1)
        XCTAssertEqual(logMessages.first, "Test message")
    }
}
