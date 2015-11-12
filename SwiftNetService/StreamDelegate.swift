//
//  StreamDelegate.swift
//  SwiftNetService
//
//  Created by Nathan Douglas on 11/11/15.
//  Copyright © 2015 Nathan Douglas. All rights reserved.
//

import Foundation
import ReactiveCocoa

// Stream tuple types.
typealias StreamTupleType = (NSInputStream, NSOutputStream)
typealias StreamTupleSignalType = ReactiveCocoa.Signal<StreamTupleType, SwiftNetServiceError>
typealias StreamTupleSignalProducerType = ReactiveCocoa.SignalProducer<StreamTupleType, SwiftNetServiceError>
typealias StreamTupleObserverType = ReactiveCocoa.Observer<StreamTupleType, SwiftNetServiceError>

// Stream event types.
typealias StreamEventType = (NSStream, NSStreamEvent)
typealias StreamEventSignalType = ReactiveCocoa.Signal<StreamEventType, SwiftNetServiceError>
typealias StreamEventSignalProducerType = ReactiveCocoa.SignalProducer<StreamEventType, SwiftNetServiceError>
typealias StreamEventObserverType = ReactiveCocoa.Observer<StreamEventType, SwiftNetServiceError>
typealias StreamEventSignalProducerTupleType = (StreamEventSignalProducerType, StreamEventSignalProducerType)
typealias StreamEventSignalProducerTupleSignalProducerType = ReactiveCocoa.SignalProducer<StreamEventSignalProducerTupleType, SwiftNetServiceError>

extension NSStream {

  private struct AssociatedKeys {
    static var streamDelegateKey: Void?
    static var streamEventSignalProducerKey: Void?
    static var streamEventObserverKey: Void?
  }

  // A strong reference to the input stream delegate so that it isn't released prematurely.
  var streamDelegate: StreamDelegate! {
    get {
      return getAssociatedObject(self, associativeKey: &AssociatedKeys.streamDelegateKey)
    }
    set(newValue) {
      setAssociatedObject(self, value: newValue, associativeKey: &AssociatedKeys.streamDelegateKey)
      assert(self.streamDelegate != nil)
    }
  }

  // The signal producer that will pass stream events from the output stream.
  var streamEventSignalProducer: StreamEventSignalProducerType? {
    get {
      return getAssociatedObject(self, associativeKey: &AssociatedKeys.streamEventSignalProducerKey)
    }
    set(newValue) {
      if let value = newValue {
        setAssociatedObject(self, value: value, associativeKey: &AssociatedKeys.streamEventSignalProducerKey)
      }
      assert(self.streamEventSignalProducer != nil)
    }
  }

  // The sink for sending the stream event into the signal.
  var streamEventObserver: StreamEventObserverType? {
    get {
      return getAssociatedObject(self, associativeKey: &AssociatedKeys.streamEventObserverKey)
    }
    set(newValue) {
      if let value = newValue {
        setAssociatedObject(self, value: value, associativeKey: &AssociatedKeys.streamEventObserverKey)
      }
      assert(self.streamEventObserver != nil)
    }
  }
  
  class func pipe() -> StreamTupleType {
    var readStream: Unmanaged<CFReadStream>?
    var writeStream: Unmanaged<CFWriteStream>?
    CFStreamCreateBoundPair(nil, &readStream, &writeStream, 4096)
    return (readStream!.takeUnretainedValue(), writeStream!.takeUnretainedValue())
  }

}

class StreamDelegate: NSObject, NSStreamDelegate {

  func openStream(stream: NSStream) -> StreamEventSignalProducerType {
    var result: StreamEventSignalProducerType
    stream.delegate = self
    stream.streamDelegate = self
    if let streamEventSignalProducer = stream.streamEventSignalProducer {
      result = streamEventSignalProducer
    } else {
      let streamEventSignalProducer = StreamEventSignalProducerType({ observer, disposable in
          let (streamEventSignal, streamEventObserver) = StreamEventSignalType.pipe()
          streamEventSignal.observe(observer)
          stream.streamEventObserver = streamEventObserver
          stream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
          stream.open()
          disposable.addDisposable({
            stream.close()
          })
        })
      stream.streamEventSignalProducer = streamEventSignalProducer
      result = streamEventSignalProducer
    }
    return result
  }

  func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
    switch eventCode {
      case NSStreamEvent.None:
        break
      case NSStreamEvent.OpenCompleted:
        break
      case NSStreamEvent.HasBytesAvailable:
        fallthrough
      case NSStreamEvent.HasSpaceAvailable:
        aStream.streamEventObserver!.sendNext((aStream, eventCode))
        break
      case NSStreamEvent.ErrorOccurred:
        aStream.streamEventObserver!.sendFailed(SwiftNetServiceError.Error(error: aStream.streamError!))
        break
      case NSStreamEvent.EndEncountered:
        aStream.streamEventObserver!.sendCompleted()
        break
      default:
        break
    }
  }

}