//
//  BrowserDelegate.swift
//  SwiftNetService
//
//  Created by Nathan Douglas on 11/2/15.
//  Copyright © 2015 Nathan Douglas. All rights reserved.
//

import Foundation
import ReactiveCocoa

typealias ServicesType = [NSNetService]
typealias ServicesSignalType = Signal<ServicesType, NSError>
typealias ServicesObserverType = Event<ServicesType, NSError>.Sink

class BrowserDelegate : NSObject, NSNetServiceBrowserDelegate {
    
    var servicesSignal : ServicesSignalType
    var services : ServicesType
    var servicesObserver : ServicesObserverType
    var isSearching : Bool = false

    internal init(servicesSignal : ServicesSignalType, servicesObserver : ServicesObserverType) {
        self.services = []
        self.servicesSignal = servicesSignal
        self.servicesObserver = servicesObserver
    }

    override convenience init() {
        let (servicesSignal, servicesObserver) = ServicesSignalType.pipe()
        self.init(servicesSignal: servicesSignal, servicesObserver: servicesObserver)
    }
    
    func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool) {
        self.services.append(service);
        if (!moreComing) {
            sendNext(self.servicesObserver, self.services)
        }
    }

    func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool) {
        if let index = self.services.indexOf(service) {
            self.services.removeAtIndex(index);
        }
        if (!moreComing) {
            sendNext(self.servicesObserver, self.services)
        }
    }
    
    func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        sendError(self.servicesObserver, errorForErrorDictionary(errorDict));
    }
    
    func netServiceBrowserWillSearch(browser: NSNetServiceBrowser) {
        self.isSearching = true
    }

    func netServiceBrowserDidStopSearch(browser: NSNetServiceBrowser) {
        self.isSearching = false
    }

}
