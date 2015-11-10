# SwiftNetService
A simple microframework for handling Bonjour services fluidly and reactively.

If one were to develop a technology built upon automatically and seamlessly connecting to desktop and mobile devices over local area networks, it could be useful to see these devices as the services join and leave the network, and to perform actions in response.

SwiftNetService is a port of [ReactiveNetService](http://github.com/ndouglas/ReactiveNetService) to Swift.  It allows easy *observation* of Bonjour/Zeroconf/Avahi/etc services on the local network as they change over time, rather than simply querying for and finding the services on the network at any particular time.

## Reference
SwiftNetService adds five functions to NSNetService:

```Swift
func resolve(timeout: NSTimeInterval) -> SignalProducerType<NSNetService, NSError>
```
    
The signal producer's side effect is to attempt to resolve the net service with the specified timeout.  

When the service is resolved, it will be returned in the signal.
    
```Swift
func lookupTXTRecord() -> SignalProducerType<NSNetService, NSError>
```

The signal producer's side effect is to attempt to look up the net service's TXT record.

When the service's TXT record has been retrieved, the net service will be returned in the signal.

```Swift
class func servicesOfType(type: String, inDomain: String) -> SignalProducerType<[NSNetService], NSError>
```

The signal producer's side effect is to begin browsing for services on the local network and returning arrays of net services as they are discovered.

```Swift
class func resolvedServicesOfType(type: String, inDomain: String, timeout: NSTimeInterval) -> SignalProducerType<[NSNetService], NSError>
```

The signal producer's side effects are:

* begin browsing for services on the local network (and return them as they are discovered)
* attempt to resolve each service as it is found, and return only the resolved services

```Swift
class func resolvedServicesWithTXTRecordsOfType(type: String, inDomain: String, timeout: NSTimeInterval) -> SignalProducerType<[NSNetService], NSError>
```
    
The signal producer's side effects are:

* begin browsing for services on the local network (and return them as they are discovered)
* attempt to resolve each service as it is found, and return only the resolved services

## Caveats
This is a learning project for Swift 2.1 and ReactiveCocoa 4.0.  It's subject to break as RAC4 changes.

This is one of my first Swift projects, and my very first using RAC4.  It's quite likely to be inefficient or broken in places, although I've done some testing and have coded carefully.

## To Do
It's not terribly resilient to errors right now (no automatic retrying, etc).  I plan to handle these better.

It only browses the "local" TLD right now.  I plan to add support for browsing domains as well.

Cocoapods and Carthage support is not quite done, but is planned.


