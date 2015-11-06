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

typealias ResolutionSignalType = Signal<NSNetService, NSError>
typealias ResolutionObserverType = Event<NSNetService, NSError>.Sink
typealias DictionarySignalType = Signal<NSNetService, NSError>
typealias DictionaryObserverType = Event<NSNetService, NSError>.Sink

private var netServiceResolutionCompleteKey: UInt8 = 0
private var netServiceResolutionSignalKey: UInt8 = 0
private var netServiceResolutionObserverKey: UInt8 = 0
private var netServiceDictionarySignalKey: UInt8 = 0
private var netServiceDictionaryObserverKey: UInt8 = 0

final class Lifted<ValueType> {
    let value: ValueType
    init(_ x: ValueType) {
        value = x
    }
}

private func lift<ValueType>(x: ValueType) -> Lifted<ValueType>  {
    return Lifted(x)
}

func setAssociatedObject<ValueType>(object: AnyObject, value: ValueType, associativeKey: UnsafePointer<Void>, policy: objc_AssociationPolicy) {
    if let v: AnyObject = value as? AnyObject {
        objc_setAssociatedObject(object, associativeKey, v,  policy)
    } else {
        objc_setAssociatedObject(object, associativeKey, lift(value),  policy)
    }
}

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

    var isResolved : Bool {
        get {
            guard let result = objc_getAssociatedObject(self, &netServiceResolutionCompleteKey) as? Bool else {
                return false
            }
            return result
        }
        set(newValue) {
            objc_setAssociatedObject(self, &netServiceResolutionCompleteKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    var resolutionSignal: ResolutionSignalType! {
        get {
            return getAssociatedObject(self, associativeKey: &netServiceResolutionSignalKey)
        }
        set(newValue) {
            setAssociatedObject(self, value: newValue, associativeKey: &netServiceResolutionSignalKey, policy: .OBJC_ASSOCIATION_RETAIN)
        }
    }

    var resolutionObserver: ResolutionObserverType! {
        get {
            return getAssociatedObject(self, associativeKey: &netServiceResolutionObserverKey)
        }
        set(newValue) {
            setAssociatedObject(self, value: newValue, associativeKey: &netServiceResolutionObserverKey, policy: .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var dictionarySignal: DictionarySignalType! {
        get {
            return getAssociatedObject(self, associativeKey: &netServiceDictionarySignalKey)
        }
        set(newValue) {
            setAssociatedObject(self, value: newValue, associativeKey: &netServiceDictionarySignalKey, policy: .OBJC_ASSOCIATION_RETAIN)
        }
    }

    var dictionaryObserver: DictionaryObserverType! {
        get {
            return getAssociatedObject(self, associativeKey: &netServiceDictionaryObserverKey)
        }
        set(newValue) {
            setAssociatedObject(self, value: newValue, associativeKey: &netServiceDictionaryObserverKey, policy: .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    func hasValidTXTRecordData() -> Bool {
        var result : Bool = false
        if let data = self.TXTRecordData() {
            result = NSNetService.dictionaryFromTXTRecordData(data).count > 0
        }
        return result
    }

}

class ServiceDelegate : NSObject, NSNetServiceDelegate {

    func resolveNetService(service: NSNetService, timeout: NSTimeInterval) -> ResolutionSignalType {
        var result : ResolutionSignalType
        service.delegate = self
        if service.isResolved {
            result = ResolutionSignalType({ observer in
                sendNext(observer, service)
                return nil
            })
        } else if service.resolutionSignal != nil {
            result = service.resolutionSignal
        } else {
            let (resolutionSignal, resolutionObserver) = ResolutionSignalType.pipe()
            service.resolutionSignal = resolutionSignal
            service.resolutionObserver = resolutionObserver
            service.resolveWithTimeout(timeout)
            result = service.resolutionSignal
        }
        return result
    }
    
    func monitorNetService(service: NSNetService) -> DictionarySignalType {
        var result : DictionarySignalType
        service.delegate = self
        if service.hasValidTXTRecordData() {
            result = DictionarySignalType({ observer in
                sendNext(observer, service)
                return nil
            })
        } else if service.dictionarySignal != nil {
            result = service.dictionarySignal
        } else {
            let (dictionarySignal, dictionaryObserver) = DictionarySignalType.pipe()
            service.dictionarySignal = dictionarySignal
            service.dictionaryObserver = dictionaryObserver
            service.startMonitoring()
            result = service.dictionarySignal
        }
        return result
    }

    func netServiceDidResolveAddress(sender: NSNetService) {
        sendNext(sender.resolutionObserver, sender)
        sender.isResolved = true
    }
    
    func netService(sender: NSNetService, didUpdateTXTRecordData data: NSData) {
        sendNext(sender.dictionaryObserver, sender)
    }

    func netService(sender: NSNetService, didNotResolve errorDict: [String : NSNumber]) {
        sendError(sender.resolutionObserver, errorForErrorDictionary(errorDict))
    }

}
