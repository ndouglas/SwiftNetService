//
//  BrowserDelegate.swift
//  SwiftNetService
//
//  Created by Nathan Douglas on 11/2/15.
//  Copyright © 2015 Nathan Douglas. All rights reserved.
//

import Foundation
import ReactiveCocoa

public class BrowserDelegate : NSObject, NSNetServiceBrowserDelegate {
    public typealias ServicesType = [NSNetService]
    var services : ServicesType
    var observer : Event<ServicesType, NSError>.Sink
    var signal : Signal<ServicesType, NSError>

    init(signal : Signal<[NSNetService], NSError>, observer : Event<[NSNetService], NSError>.Sink) {
        self.services = []
        self.signal = signal
        self.observer = observer
    }

    public override convenience init() {
        let (signal, observer) = Signal<[NSNetService], NSError>.pipe()
        self.init(signal: signal, observer: observer)
    }
    
    public func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool) {
        self.services.append(service);
        if (!moreComing) {
            sendNext(self.observer, self.services)
        }
    }

    public func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool) {
        if let index = self.services.indexOf(service) {
            self.services.removeAtIndex(index);
        }
        if (!moreComing) {
            sendNext(self.observer, self.services)
        }
    }
    
    public func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        sendError(self.observer, errorForErrorDictionary(errorDict));
    }

}
