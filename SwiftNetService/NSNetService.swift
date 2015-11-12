//
//  NSNetService.swift
//  SwiftNetService
//
//  Created by Nathan Douglas on 11/2/15.
//  Copyright © 2015 Nathan Douglas. All rights reserved.
//

import Foundation
import ReactiveCocoa

enum SwiftNetServiceError: ErrorType {
    case Unknown
    case CouldNotConnectStreams
    case Error(error: NSError)
}

// Wraps a non-object value in an object so that we can store it with getAssociatedObject/setAssociatedObject.
final class Lifted<ValueType> {
  let value: ValueType
  init(_ x: ValueType) {
    self.value = x
  }
}

// A helper function to lift a non-object value to an object.
private func lift<T>(x: T) -> Lifted<T>  {
  return Lifted(x)
}

// A wrapper for objc_setAssociatedObject() that transparently handles non-objc values.
func setAssociatedObject<ValueType>(object: AnyObject, value: ValueType, associativeKey: UnsafePointer<Void>) {
  if let v: AnyObject = value as? AnyObject {
    objc_setAssociatedObject(object, associativeKey, v, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  } else {
    objc_setAssociatedObject(object, associativeKey, lift(value), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }
}

// A wrapper for objc_getAssociatedObject() that transparently handles non-objc values.
func getAssociatedObject<ValueType>(object: AnyObject, associativeKey: UnsafePointer<Void>) -> ValueType? {
  if let v = objc_getAssociatedObject(object, associativeKey) as? ValueType {
    return v
  } else if let v = objc_getAssociatedObject(object, associativeKey) as? Lifted<ValueType> {
    return v.value
  } else {
    return nil
  }
}

extension NSNetService {

  private struct AssociatedKeys {
    static var netServiceInputStreamKey: Void?
    static var netServiceOutputStreamKey: Void?
  }

  // The input stream.
  var inputStream: NSInputStream! {
    get {
      return getAssociatedObject(self, associativeKey: &AssociatedKeys.netServiceInputStreamKey)
    }
    set(newValue) {
      setAssociatedObject(self, value: newValue, associativeKey: &AssociatedKeys.netServiceInputStreamKey)
      assert(self.inputStream != nil)
    }
  }

  // The output stream.
  var outputStream: NSOutputStream! {
    get {
      return getAssociatedObject(self, associativeKey: &AssociatedKeys.netServiceOutputStreamKey)
    }
    set(newValue) {
      setAssociatedObject(self, value: newValue, associativeKey: &AssociatedKeys.netServiceOutputStreamKey)
      assert(self.outputStream != nil)
    }
  }

}

extension Array where Element: NSNetService {

  func mapResolve(timeout: NSTimeInterval) -> [ResolutionSignalProducerType] {
    return self.map { service in service.resolve(timeout) }
  }

  func mapLookup() -> [ResolutionSignalProducerType] {
    return self.map { service in service.lookupTXTRecord() }
  }

}

extension SignalProducerType where Value == ServicesType, Error == NSError {

  func flatMapResolve(timeout: NSTimeInterval) -> ServicesSignalProducerType {
    return self.flatMap(FlattenStrategy.Latest) { combineLatest($0.mapResolve(timeout)) }
  }

  func flatMapLookup() -> ServicesSignalProducerType {
    return self.flatMap(FlattenStrategy.Latest) { combineLatest($0.mapLookup()) }
  }

}

extension NSNetService {

  /// Looks up services on the local network, attempts to resolve
  /// them, looks up their TXT records, and then passes them back.
  class func resolvedServicesWithTXTRecordsOfType(type: String, inDomain: String, timeout: NSTimeInterval) -> ServicesSignalProducerType {
    return self.resolvedServicesOfType(type, inDomain: inDomain, timeout: timeout)
      .flatMapLookup()
  }

  /// Looks up services on the local network, attempts to resolve 
  /// them, and passes them back after resolution.
  class func resolvedServicesOfType(type: String, inDomain: String, timeout: NSTimeInterval) -> ServicesSignalProducerType {
    return self.servicesOfType(type, inDomain: inDomain)
      .flatMapResolve(timeout)
  }

  /// Looks up services on the local network.
  class func servicesOfType(type: String, inDomain: String) -> ServicesSignalProducerType {
    return ServicesSignalProducerType({ observer, disposable in
          observer.sendNext([])
          let browserDelegate = BrowserDelegate()
          let browser = NSNetServiceBrowser()
          browser.delegate = browserDelegate
          browser.searchForServicesOfType(type, inDomain: inDomain)
          disposable.addDisposable(browserDelegate.servicesSignal.observe(observer))
          disposable.addDisposable {
              browser.delegate = nil
              browserDelegate.self
          }
      })
  }

  /// Looks up the TXT record for the specified net service.
  /// Notice that this will replace the existing service delegate, if 
  /// there is one and it is not a SwiftNetService ServiceDelegate.
  func resolve(timeout: NSTimeInterval) -> ResolutionSignalProducerType {
    let theDelegate = (self.delegate as? ServiceDelegate) ?? ServiceDelegate()
    return theDelegate.resolveNetService(self, timeout:timeout)
  }

  /// Looks up the TXT record for the specified net service.
  /// Notice that this will replace the existing service delegate, if 
  /// there is one and it is not a SwiftNetService ServiceDelegate.
  func lookupTXTRecord() -> DictionarySignalProducerType {
    let theDelegate = (self.delegate as? ServiceDelegate) ?? ServiceDelegate()
    return theDelegate.lookupTXTRecordForNetService(self)
  }
  
  /// Sets up publication and accepts connections, passing their 
  /// events on signal producers.
  /// Assumes we are not already published.
  func acceptConnections() -> StreamEventSignalProducerTupleSignalProducerType {
    let theDelegate = (self.delegate as? ServiceDelegate) ?? ServiceDelegate()
    return theDelegate.acceptConnectionsToNetService(self)
      .map { [weak self] tuple -> StreamEventSignalProducerTupleType in
        return self!.setupStreams(tuple)
      }
  }

  /// Connects to the net service, passing events on signal producers.
  func connect() -> StreamEventSignalProducerTupleType {
    let tuple: StreamTupleType
    do {
      try tuple = self.getStreams()
      return self.setupStreams(tuple)
    } catch SwiftNetServiceError.CouldNotConnectStreams {
      let errorProducer = StreamEventSignalProducerType(error: SwiftNetServiceError.CouldNotConnectStreams)
      return (errorProducer, errorProducer)
    } catch {
      let errorProducer = StreamEventSignalProducerType(error: SwiftNetServiceError.Unknown)
      return (errorProducer, errorProducer)
    }
  }

  /// Gets streams to connect to the service.
  func getStreams() throws -> StreamTupleType {
    var inputStream: NSInputStream?
    var outputStream: NSOutputStream?
    self.getInputStream(&inputStream, outputStream: &outputStream)
    guard let resultInputStream = inputStream else {
      throw SwiftNetServiceError.CouldNotConnectStreams
    }
    guard let resultOutputStream = outputStream else {
      throw SwiftNetServiceError.CouldNotConnectStreams
    }
    return (resultInputStream, resultOutputStream)
  }

  /// Sets up streams and attaches signal producers to them.
  func setupStreams(streams: StreamTupleType) -> StreamEventSignalProducerTupleType {
    return self.setupStreams(streams.0, streams.1)
  }

  /// Sets up streams and attaches signal producers to them.
  func setupStreams(inputStream: NSInputStream, outputStream: NSOutputStream) -> StreamEventSignalProducerTupleType {
    return (StreamDelegate().openStream(inputStream), StreamDelegate().openStream(outputStream))
  }

}

func errorForErrorDictionary(errorDictionary : [String: NSNumber]) -> NSError {
    return NSError(domain: NSNetServicesErrorDomain, code:(errorDictionary[NSNetServicesErrorCode]?.integerValue)!, userInfo:nil);
}
