//
//  BrowserDelegateTests.swift
//  SwiftNetService
//
//  Created by Nathan Douglas on 11/3/15.
//  Copyright © 2015 Nathan Douglas. All rights reserved.
//

import XCTest
@testable import SwiftNetService

class ServiceDelegate : NSObject, NSNetServiceDelegate {
    var expectation : XCTestExpectation
    
    init(expectation : XCTestExpectation) {
        self.expectation = expectation
    }

    @objc func netService(sender: NSNetService, didNotPublish errorDict: [String : NSNumber]) {
        XCTFail("Failed to publish service: \(errorForErrorDictionary(errorDict))")
    }

    @objc func netServiceDidPublish(sender: NSNetService) {
        self.expectation.fulfill()
        NSLog("Did publish service: \(sender)")
    }

    @objc func netServiceWillPublish(sender: NSNetService) {
        NSLog("Will publish service: \(sender)")
    }

}

class TestService {
    var UUID : String
    var type : String
    var service : NSNetService
    var delegate : ServiceDelegate?
    
    init(port : Int32) {
        self.UUID = NSUUID().UUIDString
        self.type = "_\(self.UUID)._tcp"
        self.service = NSNetService(domain: "local", type: self.type, name: self.UUID, port: port)
    }
    
    func publishAndFulfillExpectation(expectation: XCTestExpectation) {
        self.delegate = ServiceDelegate(expectation: expectation)
        self.service.delegate = self.delegate
        self.service.publish()
    }
    
}


class BrowserDelegateTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testBrowserDelegate() {
        // We're going to publish a net service and see if we find it.
        let myTestService = TestService(port: 2015)
        let expectation = self.expectationWithDescription("published")
        myTestService.publishAndFulfillExpectation(expectation)
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
        // Getting this far means that the service was created and published successfully.
    }
   
    
}
