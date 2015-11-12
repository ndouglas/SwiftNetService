//
//  StreamDelegateTests.swift
//  SwiftNetService
//
//  Created by Nathan Douglas on 11/12/15.
//  Copyright © 2015 Nathan Douglas. All rights reserved.
//

import XCTest
@testable import SwiftNetService

class StreamDelegateTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testStreamDelegateWithPipe() {
        // We'll test with a pipe first, since that should be the easiest.
        let (inputStream, outputStream) = NSStream.pipe()
        let inputExpectation1 = self.expectationWithDescription("stream opened")
        let outputExpectation1 = self.expectationWithDescription("stream opened")
        let inputExpectation2 = self.expectationWithDescription("signal started")
        let outputExpectation2 = self.expectationWithDescription("signal started")
        let inputExpectation3 = self.expectationWithDescription("stream closed")
        let outputExpectation3 = self.expectationWithDescription("stream closed")
        let inputExpectation4 = self.expectationWithDescription("signal completed")
        let outputExpectation4 = self.expectationWithDescription("signal completed")
        let inputStreamSignalProducer = StreamDelegate().openStream(inputStream)
          .on(started: {
              print("Started")
              inputExpectation1.fulfill()
          }, event: { event in
              print("Event: \(event)")
          }, failed: { error in
              print("Failed: \(error)")
          }, completed: {
              print("Completed")
              inputExpectation4.fulfill()
          }, interrupted: {
              print("Interrupted")
          }, terminated: {
              print("Terminated")
          }, disposed: {
              print("Disposed")
          }, next: { value in
              print("Next: \(value)")
              switch value.1 {
                case NSStreamEvent.None:
                  break
                case NSStreamEvent.OpenCompleted:
                  inputExpectation2.fulfill()
                  break
                case NSStreamEvent.HasBytesAvailable:
                  if let inputStream = value.0 as? NSInputStream {
                    var buffer = [UInt8](count: 4096, repeatedValue: 0)
                    let len = inputStream.read(&buffer, maxLength: buffer.count)
                    if(len > 0) {
                      let output = NSString(bytes: &buffer, length: buffer.count, encoding: NSUTF8StringEncoding)
                      NSLog("server said: %@", output!)
                    }
                    inputStream.close()
                  }
                  break
                case NSStreamEvent.HasSpaceAvailable:
                  break
                case NSStreamEvent.ErrorOccurred:
                  break
                case NSStreamEvent.EndEncountered:
                  inputExpectation3.fulfill()
                  break
                default:
                  break
              }
          })
        let outputStreamSignalProducer = StreamDelegate().openStream(outputStream)
          .on(started: {
              print("Started")
              outputExpectation1.fulfill()
          }, event: { event in
              print("Event: \(event)")
          }, failed: { error in
              print("Failed: \(error)")
          }, completed: {
              print("Completed")
              outputExpectation4.fulfill()
          }, interrupted: {
              print("Interrupted")
          }, terminated: {
              print("Terminated")
          }, disposed: {
              print("Disposed")
          }, next: { value in
              print("Next: \(value)")
              switch value.1 {
                case NSStreamEvent.None:
                  break
                case NSStreamEvent.OpenCompleted:
                  outputExpectation2.fulfill()
                  break
                case NSStreamEvent.HasBytesAvailable:
                  break
                case NSStreamEvent.HasSpaceAvailable:
                  if let outputStream = value.0 as? NSOutputStream {
                    let data = "hello".dataUsingEncoding(NSStringEncoding(NSUTF8StringEncoding))
                    outputStream.write(UnsafePointer(data!.bytes), maxLength: data!.length)
                    outputStream.close()
                  }
                  break
                case NSStreamEvent.ErrorOccurred:
                  break
                case NSStreamEvent.EndEncountered:
                  outputExpectation3.fulfill()
                  break
                default:
                  break
              }
          })
        inputStreamSignalProducer.start()
        outputStreamSignalProducer.start()
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
