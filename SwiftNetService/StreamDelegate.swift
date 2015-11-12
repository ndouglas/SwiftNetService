//
//  StreamDelegate.swift
//  SwiftNetService
//
//  Created by Nathan Douglas on 11/11/15.
//  Copyright © 2015 Nathan Douglas. All rights reserved.
//

import Foundation
import ReactiveCocoa

typealias StreamEventSignalValueType = (NSStream, NSStreamEvent)
typealias StreamEventSignalType = Signal<StreamEventSignalValueType, NSError>
typealias StreamEventSignalProducerType = SignalProducer<StreamEventSignalValueType, NSError>
typealias StreamEventObserverType = Observer<StreamEventSignalValueType, NSError>
typealias StreamEventHandlerType = (StreamEventSignalValueType) -> ()

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
    aStream.streamEventObserver!.sendNext((aStream, eventCode))
  }

}
