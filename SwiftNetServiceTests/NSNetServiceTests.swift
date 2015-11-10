//
//  NSNetServiceTests.swift
//  SwiftNetServiceTests
//
//  Created by Nathan Douglas on 11/2/15.
//  Copyright © 2015 Nathan Douglas. All rights reserved.
//

import XCTest
import ReactiveCocoa
@testable import SwiftNetService

class NSNetServiceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testServicesOfType() {
        // We're going to publish a net service and see if we find it.
        
        let myTestService = TestService(port: 2015)
        let expectation = self.expectationWithDescription("published")
        myTestService.publishAndFulfillExpectation(expectation)
        self.waitForExpectationsWithTimeout(2.5, handler: nil)
        // The service was created and published successfully.
        
        // Next, let's start up a browser and try to find the service.
        let expectation2 = self.expectationWithDescription("found")
        NSNetService.servicesOfType(myTestService.type, inDomain: "local")
            .on(next: { value in
                if value.containsTestService(myTestService) {
                    expectation2.fulfill()
                }
            })
            .start()
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
        // The service was successfully discovered.
    }

    func testResolvedServicesOfType() {
        // We're going to publish a net service and see if we find it.
        
        let myTestService = TestService(port: 2015)
        let expectation = self.expectationWithDescription("published")
        myTestService.publishAndFulfillExpectation(expectation)
        self.waitForExpectationsWithTimeout(2.5, handler: nil)
        // The service was created and published successfully.
        
        // Next, let's start up a browser and try to find the service.
        let expectation2 = self.expectationWithDescription("found")
        NSNetService.resolvedServicesOfType(myTestService.type, inDomain: "local", timeout:10.0)
            .on(next: { value in
                if value.containsTestService(myTestService) {
                    expectation2.fulfill()
                }
            })
            .start()
        self.waitForExpectationsWithTimeout(10.0, handler: nil)
        // The service was successfully discovered.
    }

    func testLookupServicesOfType() {
        // We're going to publish a net service and see if we find it.
        
        let myTestService = TestService(port: 2015)
        let expectation = self.expectationWithDescription("published")
        myTestService.publishAndFulfillExpectation(expectation)
        self.waitForExpectationsWithTimeout(2.5, handler: nil)
        // The service was created and published successfully.
        
        // Next, let's start up a browser and try to find the service.
        let expectation2 = self.expectationWithDescription("found")
        NSNetService.resolvedServicesWithTXTRecordsOfType(myTestService.type, inDomain: "local", timeout:10.0)
            .on(next: { value in
                if value.containsTestService(myTestService) {
                    expectation2.fulfill()
                }
            })
            .start()
        self.waitForExpectationsWithTimeout(10.0, handler: nil)
        // The service was successfully discovered.
    }
    
}

