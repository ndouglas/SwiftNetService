//
//  ServiceDelegateTests.swift
//  SwiftNetService
//
//  Created by Nathan Douglas on 11/5/15.
//  Copyright © 2015 Nathan Douglas. All rights reserved.
//

import XCTest
import ReactiveCocoa

@testable import SwiftNetService

extension TestService {

    func resolveAndFulfillExpectation(expectation: XCTestExpectation, timeout: NSTimeInterval) {
        if self.browser == nil {
            self.browser = NSNetServiceBrowser()
            self.clientDelegate = BrowserDelegate()
            self.browser!.delegate = self.clientDelegate
        }
        self.clientDelegate?.servicesSignal
            .reduceToServiceMatchingTestService(self)
            .flatMap(.Latest) { service in
                return ServiceDelegate().resolveNetService(service, timeout: timeout)
            }
            .observeCompleted { expectation.fulfill() }
        if !self.clientDelegate!.isSearching {
            self.browser!.searchForServicesOfType(self.type, inDomain: "local")
        }
    }

}

class ServiceDelegateTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testBrowserDelegateDiscovery() {
        // We're going to publish a net service and see if we find and resolve it.
        
        // Let's start up that service.
        let myTestService = TestService(port: 2015)
        let expectation = self.expectationWithDescription("published")
        myTestService.publishAndFulfillExpectation(expectation)
        self.waitForExpectationsWithTimeout(2.5, handler: nil)
        // The service was created and published successfully.
        
        // Next, let's start up a browser and try to find the service.
        let expectation2 = self.expectationWithDescription("found")
        myTestService.discoverAndFulfillExpectation(expectation2)
        self.waitForExpectationsWithTimeout(2.5, handler: nil)
        // The service was discovered.
        
        let expectation3 = self.expectationWithDescription("resolved")
        myTestService.resolveAndFulfillExpectation(expectation3, timeout: 5.0)
    }

}
