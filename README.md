# SwiftNetService
A simple microframework for handling Bonjour services fluidly and reactively.

If one were to develop a technology built upon automatically and seamlessly connecting to desktop and mobile devices over local area networks, it could be useful to see these devices as the services join and leave the network, and to perform actions in response.

SwiftNetService is a port of [ReactiveNetService](http://github.com/ndouglas/ReactiveNetService) to Swift.  It allows easy *observation* of Bonjour/Zeroconf/Avahi/etc services on the local network as they change over time, rather than simply querying for and finding the services on the network at any particular time.

This is also a learning project for Swift 2.1 and ReactiveCocoa 4.0.'