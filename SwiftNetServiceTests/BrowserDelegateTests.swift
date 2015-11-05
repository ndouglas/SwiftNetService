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

class GenericServiceDelegate : NSObject, NSNetServiceDelegate {
    typealias OnDidNotPublishType = (NSNetService, NSError) -> ()
    typealias OnDidPublishType = (NSNetService) -> ()
    typealias OnDidStopType = (NSNetService) -> ()
    typealias OnWillPublishType = (NSNetService) -> ()
    var onDidNotPublish : OnDidNotPublishType?
    var onDidPublish : OnDidPublishType?
    var onDidStop : OnDidStopType?
    var onWillPublish : OnWillPublishType?

    @objc func netService(sender: NSNetService, didNotPublish errorDict: [String : NSNumber]) {
        if self.onDidNotPublish != nil {
            self.onDidNotPublish!(sender, errorForErrorDictionary(errorDict))
            self.onDidNotPublish = nil
        }
        NSLog("Failed to publish service: \(errorForErrorDictionary(errorDict))")
    }

    @objc func netServiceDidPublish(sender: NSNetService) {
        if self.onDidPublish != nil {
            self.onDidPublish!(sender)
            self.onDidPublish = nil
        }
        NSLog("Did publish service: \(sender)")
    }
    
    @objc func netServiceDidStop(sender: NSNetService) {
        if self.onDidStop != nil {
            self.onDidStop!(sender)
            self.onDidStop = nil
        }
        NSLog("Did stop publishing service: \(sender)")
    }

    @objc func netServiceWillPublish(sender: NSNetService) {
        if self.onWillPublish != nil {
            self.onWillPublish!(sender)
            self.onWillPublish = nil
        }
        NSLog("Will publish service: \(sender)")
    }

}

extension Array where Element: NSNetService {
    func containsTestService(testService: TestService) -> Bool {
        return self.filter({ $0.name == testService.UUID }).count > 0
    }
}

extension SignalType where T == SwiftNetService.ServicesType {

    func skipWhileContainsTestService(testService: TestService) -> Signal<SwiftNetService.ServicesType, E> {
        return self.skipWhile { $0.containsTestService(testService) }
    }

    func skipWhileNotContainsTestService(testService: TestService) -> Signal<SwiftNetService.ServicesType, E> {
        return self.skipWhile { !$0.containsTestService(testService) }
    }

    func takeUntilContainsTestService(testService: TestService) -> Signal<SwiftNetService.ServicesType, E> {
        return self.takeWhile { !$0.containsTestService(testService) }
    }

    func takeUntilNotContainsTestService(testService: TestService) -> Signal<SwiftNetService.ServicesType, E> {
        return self.takeWhile { $0.containsTestService(testService) }
    }

}

class TestService {
    var UUID : String
    var type : String
    var service : NSNetService
    var serverDelegate : GenericServiceDelegate?
    var browser : NSNetServiceBrowser?
    var clientDelegate : BrowserDelegate?
    
    init(port : Int32) {
        self.UUID = NSUUID().UUIDString
        self.type = "_\(self.UUID)._tcp"
        self.service = NSNetService(domain: "local", type: self.type, name: self.UUID, port: port)
    }
    
    func publishAndFulfillExpectation(expectation: XCTestExpectation) {
        if self.serverDelegate == nil {
            self.serverDelegate = GenericServiceDelegate()
            self.service.delegate = self.serverDelegate
        }
        self.serverDelegate?.onDidPublish = { service in
            expectation.fulfill()
        }
        self.service.publish()
    }

    func stopAndFulfillExpectation(expectation: XCTestExpectation) {
        if self.serverDelegate == nil {
            self.serverDelegate = GenericServiceDelegate()
            self.service.delegate = self.serverDelegate
        }
        self.serverDelegate?.onDidStop = { service in
            expectation.fulfill()
        }
        self.service.stop()
    }
    
    func discoverAndFulfillExpectation(expectation: XCTestExpectation) {
        if self.browser == nil {
            self.browser = NSNetServiceBrowser()
            self.clientDelegate = BrowserDelegate()
            self.browser!.delegate = self.clientDelegate
        }
        self.clientDelegate?.servicesSignal
            .skipWhileNotContainsTestService(self)
            .takeUntilContainsTestService(self)
            .observeCompleted { expectation.fulfill() }
        if !self.clientDelegate!.isSearching {
            self.browser!.searchForServicesOfType(self.type, inDomain: "local")
        }
    }

    func undiscoverAndFulfillExpectation(expectation: XCTestExpectation) {
        self.clientDelegate?.servicesSignal
            .skipWhileContainsTestService(self)
            .takeUntilNotContainsTestService(self)
            .observeCompleted { expectation.fulfill() }
        if self.browser == nil {
            self.browser = NSNetServiceBrowser()
            self.clientDelegate = BrowserDelegate()
            self.browser!.delegate = self.clientDelegate
        }
        if !self.clientDelegate!.isSearching {
            self.browser!.searchForServicesOfType(self.type, inDomain: "local")
        }
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

    func testBrowserDelegateRediscovery() {
        // We're going to publish a net service and see if we find it,
        // then stop it and make sure it disappears from the signal,
        // then re-publish it and see if we find it.
        
        // First, let's start the net service.
        let myTestService = TestService(port: 2015)
        let expectation = self.expectationWithDescription("published")
        myTestService.publishAndFulfillExpectation(expectation)
        self.waitForExpectationsWithTimeout(2.5, handler: nil)
        // The service was created and published.
        
        // Next, let's start up a browser and try to discover the service.
        let expectation2 = self.expectationWithDescription("discovered")
        myTestService.discoverAndFulfillExpectation(expectation2)
        self.waitForExpectationsWithTimeout(2.5, handler: nil)
        // The service was discovered.
        
        // Next, let's stop the service.
        let expectation3 = self.expectationWithDescription("stopped")
        myTestService.stopAndFulfillExpectation(expectation3)
        self.waitForExpectationsWithTimeout(2.5, handler: nil)
        // The service was stopped.
        
        // Next, let's see if the browser notices the absence of the service.
        let expectation4 = self.expectationWithDescription("undiscovered")
        myTestService.undiscoverAndFulfillExpectation(expectation4)
        self.waitForExpectationsWithTimeout(2.5, handler: nil)
        // The service's absence was noticed.

        // Next, let's restart the net service.
        let expectation5 = self.expectationWithDescription("republished")
        myTestService.publishAndFulfillExpectation(expectation5)
        self.waitForExpectationsWithTimeout(2.5, handler: nil)
        // The service was restarted.
        
        // Next, let's start up a browser and try to find the service.
        let expectation6 = self.expectationWithDescription("rediscovered")
        myTestService.discoverAndFulfillExpectation(expectation6)
        self.waitForExpectationsWithTimeout(2.5, handler: nil)
        // The service was discovered.

        // Next, let's stop the service.
        let expectation7 = self.expectationWithDescription("stopped")
        myTestService.stopAndFulfillExpectation(expectation7)
        self.waitForExpectationsWithTimeout(2.5, handler: nil)
        // The service was stopped.
        
        // Next, let's see if the browser notices the absence of the service.
        let expectation8 = self.expectationWithDescription("undiscovered")
        myTestService.undiscoverAndFulfillExpectation(expectation8)
        self.waitForExpectationsWithTimeout(2.5, handler: nil)
        // The service's absence was noticed.

        // Passing means that the service transitioned through a few states and was noticed doing so.
    }
   
    func testMultipleBrowserDelegateDiscovery() {
        // We're going to publish several net services and see if we find them.
        
        var myTestServices : [TestService] = []
        for index in 0...20 {
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
