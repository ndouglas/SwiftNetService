//
//  NSNetService.swift
//  SwiftNetService
//
//  Created by Nathan Douglas on 11/2/15.
//  Copyright © 2015 Nathan Douglas. All rights reserved.
//

import Foundation
import ReactiveCocoa

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
        if let theDelegate = self.delegate as? ServiceDelegate {
            return theDelegate.resolveNetService(self, timeout:timeout)
        } else {
            return ServiceDelegate().resolveNetService(self, timeout:timeout)
        }
    }
    
    /// Looks up the TXT record for the specified net service.
    /// Notice that this will replace the existing service delegate, if 
    /// there is one and it is not a SwiftNetService ServiceDelegate.
    func lookupTXTRecord() -> DictionarySignalProducerType {
        if let theDelegate = self.delegate as? ServiceDelegate {
            return theDelegate.lookupTXTRecordForNetService(self)
        } else {
            return ServiceDelegate().lookupTXTRecordForNetService(self)
        }
    }

}

func errorForErrorDictionary(errorDictionary : [String: NSNumber]) -> NSError {
    return NSError(domain: NSNetServicesErrorDomain, code:(errorDictionary[NSNetServicesErrorCode]?.integerValue)!, userInfo:nil);
}
