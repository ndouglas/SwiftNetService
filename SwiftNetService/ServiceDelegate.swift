//
//  ServiceDelegate.swift
//  SwiftNetService
//
//  Created by Nathan Douglas on 11/5/15.
//  Copyright © 2015 Nathan Douglas. All rights reserved.
//

import Foundation
import ReactiveCocoa
import ObjectiveC

typealias ResolutionSignalProducerType = ReactiveCocoa.SignalProducer<NSNetService, NSError>
typealias ResolutionObserverType = ReactiveCocoa.Observer<NSNetService, NSError>
typealias DictionarySignalProducerType = ReactiveCocoa.SignalProducer<NSNetService, NSError>
typealias DictionaryObserverType = ReactiveCocoa.Observer<NSNetService, NSError>

extension NSNetService {

  private struct AssociatedKeys {
    static var netServiceResolutionDelegateKey: Void?
    static var netServiceResolutionCompleteKey: Void?
    static var netServiceResolutionSignalProducerKey: Void?
    static var netServiceResolutionObserverKey: Void?
    static var netServiceDictionarySignalProducerKey: Void?
    static var netServiceDictionaryObserverKey: Void?
  }

  // We mark the net service as resolved after it's been resolved.
  var isResolved : Bool {
  get {
    guard let result = objc_getAssociatedObject(self, &AssociatedKeys.netServiceResolutionCompleteKey) as? Bool else {
      return false
    }
    return result
  }
    set(newValue) {
      objc_setAssociatedObject(self, &AssociatedKeys.netServiceResolutionCompleteKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }

  // A strong reference to the delegate so that it isn't released prematurely.
  var resolutionDelegate: ServiceDelegate! {
    get {
      return getAssociatedObject(self, associativeKey: &AssociatedKeys.netServiceResolutionDelegateKey)
    }
    set(newValue) {
      setAssociatedObject(self, value: newValue, associativeKey: &AssociatedKeys.netServiceResolutionDelegateKey)
      assert(self.resolutionDelegate != nil)
    }
  }

  // The signal that will pass the resolved net service.
  var resolutionSignalProducer: ResolutionSignalProducerType? {
    get {
      return getAssociatedObject(self, associativeKey: &AssociatedKeys.netServiceResolutionSignalProducerKey)
    }
    set(newValue) {
      if let value = newValue {
        setAssociatedObject(self, value: value, associativeKey: &AssociatedKeys.netServiceResolutionSignalProducerKey)
      }
      assert(self.resolutionSignalProducer != nil)
    }
  }

  // The sink for sending the net service into the resolution signal.
  var resolutionObserver: ResolutionObserverType? {
    get {
      return getAssociatedObject(self, associativeKey: &AssociatedKeys.netServiceResolutionObserverKey)
    }
    set(newValue) {
      if let value = newValue {
        setAssociatedObject(self, value: value, associativeKey: &AssociatedKeys.netServiceResolutionObserverKey)
      }
      assert(self.resolutionObserver != nil)
    }
  }

  // The signal that passes the net service when its TXT record is updated.
  var dictionarySignalProducer: DictionarySignalProducerType? {
    get {
      return getAssociatedObject(self, associativeKey: &AssociatedKeys.netServiceDictionarySignalProducerKey)
    }
    set(newValue) {
      if let value = newValue {
        setAssociatedObject(self, value: value, associativeKey: &AssociatedKeys.netServiceDictionarySignalProducerKey)
      }
      assert(self.dictionarySignalProducer != nil)
    }
  }

  // The sink for sending the net service into the dictionary signal.
  var dictionaryObserver: DictionaryObserverType? {
    get {
      return getAssociatedObject(self, associativeKey: &AssociatedKeys.netServiceDictionaryObserverKey)
    }
    set(newValue) {
      if let value = newValue {
        setAssociatedObject(self, value: value, associativeKey: &AssociatedKeys.netServiceDictionaryObserverKey)
      }
      assert(self.dictionaryObserver != nil)
    }
  }

  // Does this net service have a meaningful TXT record?
  func hasValidTXTRecordData() -> Bool {
    var result : Bool = false
    if let data = self.TXTRecordData() {
      result = NSNetService.dictionaryFromTXTRecordData(data).count > 0
    }
    return result
  }

}

class ServiceDelegate : NSObject, NSNetServiceDelegate {

  func resolveNetService(service: NSNetService, timeout: NSTimeInterval) -> ResolutionSignalProducerType {
    var result : ResolutionSignalProducerType
    service.delegate = self
    service.resolutionDelegate = self
    if service.isResolved {
      result = ResolutionSignalProducerType({ observer, disposable in
          observer.sendNext(service)
          observer.sendCompleted()
        })
    } else if let resolutionSignalProducer = service.resolutionSignalProducer {
      result = resolutionSignalProducer
    } else {
      let resolutionSignalProducer = ResolutionSignalProducerType({ observer, disposable in
          let (resolutionSignal, resolutionObserver) = Signal<NSNetService, NSError>.pipe()
          resolutionSignal.observe(observer)
          service.resolutionObserver = resolutionObserver
          service.resolveWithTimeout(timeout)
          disposable.addDisposable({
              service.stop()
            })
        })
      service.resolutionSignalProducer = resolutionSignalProducer
      result = resolutionSignalProducer
    }
    return result
  }

  func lookupTXTRecordForNetService(service: NSNetService) -> DictionarySignalProducerType {
    return self.monitorTXTRecordForNetService(service).take(1)
  }

  func monitorTXTRecordForNetService(service: NSNetService) -> DictionarySignalProducerType {
    var result : DictionarySignalProducerType
    service.delegate = self
    service.resolutionDelegate = self
    if let dictionarySignalProducer = service.dictionarySignalProducer {
      result = dictionarySignalProducer
    } else {
      let dictionarySignalProducer = DictionarySignalProducerType({ observer, disposable in
          let (dictionarySignal, dictionaryObserver) = Signal<NSNetService, NSError>.pipe()
          dictionarySignal.observe(observer)
          service.dictionaryObserver = dictionaryObserver
          service.startMonitoring()
          disposable.addDisposable({
              service.stop()
            })
        })
      service.dictionarySignalProducer = dictionarySignalProducer
      result = dictionarySignalProducer
    }
    return result
  }

  func netServiceDidResolveAddress(sender: NSNetService) {
    sender.resolutionObserver!.sendNext(sender)
    sender.resolutionObserver!.sendCompleted()
    sender.isResolved = true
  }

  func netService(sender: NSNetService, didUpdateTXTRecordData data: NSData) {
    sender.dictionaryObserver!.sendNext(sender)
  }

  func netService(sender: NSNetService, didNotResolve errorDict: [String : NSNumber]) {
    sender.resolutionObserver!.sendFailed(errorForErrorDictionary(errorDict))
  }

}
