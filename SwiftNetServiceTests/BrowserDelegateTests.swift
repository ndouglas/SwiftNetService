//
//  BrowserDelegateTests.swift
//  SwiftNetService
//
//  Created by Nathan Douglas on 11/3/15.
//  Copyright © 2015 Nathan Douglas. All rights reserved.
//

import XCTest
import ReactiveCocoa

@testable import SwiftNetService

class ServicePublicationDelegate : NSObject, NSNetServiceDelegate {

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
    
    @objc func netServiceDidStop(sender: NSNetService) {
        NSLog("Did stop publishing service: \(sender)")
    }

    @objc func netServiceWillPublish(sender: NSNetService) {
        NSLog("Will publish service: \(sender)")
    }

}

class TestService {
    var UUID : String
    var type : String
    var service : NSNetService
    var publicationDelegate : ServicePublicationDelegate?
    var browser : NSNetServiceBrowser?
    var discoveryDelegate : BrowserDelegate?
    
    init(port : Int32) {
        self.UUID = NSUUID().UUIDString
        self.type = "_\(self.UUID)._tcp"
        self.service = NSNetService(domain: "local", type: self.type, name: self.UUID, port: port)
    }
    
    func publishAndFulfillExpectation(expectation: XCTestExpectation) {
        self.publicationDelegate = ServicePublicationDelegate(expectation: expectation)
        self.service.delegate = self.publicationDelegate
        self.service.publish()
    }

    func stopAndFulfillExpectation(expectation: XCTestExpectation) {
        self.publicationDelegate = ServicePublicationDelegate(expectation: expectation)
        self.service.delegate = self.publicationDelegate
        self.service.stop()
    }
    
    func discoverAndFulfillExpectation(expectation: XCTestExpectation) {
        self.browser = NSNetServiceBrowser()
        self.discoveryDelegate = BrowserDelegate()
        self.browser!.delegate = self.discoveryDelegate
        self.discoveryDelegate?.servicesSignal.observeNext({ (services: [NSNetService]) -> () in
            if let theService = services.filter({ $0.name == self.UUID }).first {
                NSLog("Did discover service: \(theService)")
                expectation.fulfill()
            }
        })
        self.browser!.searchForServicesOfType(self.type, inDomain: "local")
    }
}


class BrowserDelegateTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testBrowserDelegateDiscovery() {
        // We're going to publish a net service and see if we find it.
        
        let myTestService = TestService(port: 2015)
        let expectation = self.expectationWithDescription("published")
        myTestService.publishAndFulfillExpectation(expectation)
        self.waitForExpectationsWithTimeout(2.5, handler: nil)
        // Getting this far means that the service was created and published successfully.
        
        // Next, let's start up a browser and try to find the service.
        let expectation2 = self.expectationWithDescription("found")
        myTestService.discoverAndFulfillExpectation(expectation2)
        self.waitForExpectationsWithTimeout(2.5, handler: nil)
        // Passing means that the service was successfully discovered.
    }
   
    func testMultipleBrowserDelegateDiscovery() {
        // We're going to publish several net services and see if we find them.
        
        var myTestServices : [TestService] = []
        
        for index in 0...10 {
            myTestServices.append(TestService(port: 2015+index))
        }
        let expectations = myTestServices.map { (service: TestService) -> XCTestExpectation in
            return self.expectationWithDescription("published service \(service.UUID)")
        }
        for index in 0...myTestServices.count-1 {
            myTestServices[index].publishAndFulfillExpectation(expectations[index])
        }
        self.waitForExpectationsWithTimeout(2.5, handler: nil)
        // Getting this far means that the services were created and published successfully.

        // Next, let's start up browsers and try to find the services.
        let expectations2 = myTestServices.map { (service: TestService) -> XCTestExpectation in
            return self.expectationWithDescription("found service \(service.UUID)")
        }
        for index in 0...myTestServices.count-1 {
            myTestServices[index].discoverAndFulfillExpectation(expectations2[index])
        }
        self.waitForExpectationsWithTimeout(2.5, handler: nil)
        // Passing means that the services were successfully discovered.
    }
    
}
