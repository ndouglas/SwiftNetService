//
//  BrowserDelegate.swift
//  SwiftNetService
//
//  Created by Nathan Douglas on 11/2/15.
//  Copyright © 2015 Nathan Douglas. All rights reserved.
//

import Foundation
import ReactiveCocoa

public typealias ServicesType = [NSNetService]
public typealias ServicesSignalType = Signal<ServicesType, NSError>
public typealias ServicesObserverType = Event<ServicesType, NSError>.Sink

public class BrowserDelegate : NSObject, NSNetServiceBrowserDelegate {
    
    public var servicesSignal : ServicesSignalType
    public var services : ServicesType
    private var servicesObserver : ServicesObserverType
    public var isSearching : Bool = false

    internal init(servicesSignal : ServicesSignalType, servicesObserver : ServicesObserverType) {
        self.services = []
        self.servicesSignal = servicesSignal
        self.servicesObserver = servicesObserver
    }

    public override convenience init() {
        let (servicesSignal, servicesObserver) = ServicesSignalType.pipe()
        self.init(servicesSignal: servicesSignal, servicesObserver: servicesObserver)
    }
    
    public func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool) {
        self.services.append(service);
        if (!moreComing) {
            sendNext(self.servicesObserver, self.services)
        }
    }

    public func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool) {
        if let index = self.services.indexOf(service) {
            self.services.removeAtIndex(index);
        }
        if (!moreComing) {
            sendNext(self.servicesObserver, self.services)
        }
    }
    
    public func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        sendError(self.servicesObserver, errorForErrorDictionary(errorDict));
    }
    
    public func netServiceBrowserWillSearch(browser: NSNetServiceBrowser) {
        self.isSearching = true
    }

    public func netServiceBrowserDidStopSearch(browser: NSNetServiceBrowser) {
        self.isSearching = false
    }

}
