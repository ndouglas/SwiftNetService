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
typealias ServicesSignalType = ReactiveCocoa.Signal<ServicesType, NSError>
typealias ServicesSignalProducerType = ReactiveCocoa.SignalProducer<ServicesType, NSError>
typealias ServicesObserverType = ReactiveCocoa.Observer<ServicesType, NSError>

class BrowserDelegate : NSObject, NSNetServiceBrowserDelegate {

  var servicesSignal : ServicesSignalType
  var services : ServicesType
  var servicesObserver : ServicesObserverType
  var isSearching : Bool = false
  var servicesSignalProducer : ServicesSignalProducerType

  internal init(servicesSignal : ServicesSignalType, servicesObserver : ServicesObserverType) {
    self.services = []
    self.servicesObserver = servicesObserver
    self.servicesSignal = servicesSignal
    let (producer, sink) = SignalProducer<ServicesType, NSError>.buffer(1)
    servicesSignal.observe(sink)
    self.servicesSignalProducer = producer
  }

  override convenience init() {
    let (servicesSignal, servicesObserver) = ServicesSignalType.pipe()
    self.init(servicesSignal: servicesSignal, servicesObserver: servicesObserver)
  }

  func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool) {
    self.services.append(service);
    if (!moreComing) {
      self.servicesObserver.sendNext(self.services)
    }
  }

  func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool) {
    if let index = self.services.indexOf(service) {
      self.services.removeAtIndex(index);
    }
    if (!moreComing) {
      self.servicesObserver.sendNext(self.services)
    }
  }

  func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
    self.servicesObserver.sendFailed(errorForErrorDictionary(errorDict));
  }

  func netServiceBrowserWillSearch(browser: NSNetServiceBrowser) {
    self.isSearching = true
  }

  func netServiceBrowserDidStopSearch(browser: NSNetServiceBrowser) {
    self.isSearching = false
  }

}
