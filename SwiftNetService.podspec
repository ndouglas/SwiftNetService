Pod::Spec.new do |s|
  s.name                        = "SwiftNetService"
  s.version                     = "0.0.1"
  s.summary                     = "A simple microframework for handling Bonjour services fluidly and reactively."
  s.description                 = <<-DESC
				A simple microframework for handling Bonjour services fluidly and reactively.

                                This is largely based on Chris Devereux's ReactiveNetService, but adds 
                                some more convenience methods, handles TXT record updates, and so forth. 
                                I started with Chris' work but spent enough time hacking around issues 
                                with my (admittedly strange) usage scenarios that I wanted to create a 
                                distinct project rather than pollute his project with my weird edge cases :)

				If one were to develop a technology built upon automatically and seamlessly 
				connecting to desktop and mobile devices over local area networks, it could 
				be useful to see these devices as the services join and leave the network, 
				and to perform actions in response.

				SwiftNetService is a port of [ReactiveNetService](http://github.com/ndouglas/ReactiveNetService) 
				to Swift. It allows easy observation of Bonjour/Zeroconf/Avahi/etc services 
				on the local network as they change over time, rather than simply querying 
				for and finding the services on the network at any particular time.
                                DESC
  s.homepage                    = "https://github.com/ndouglas/SwiftNetService"
  s.license                     = {
					:type => "Public Domain", 
					:file => "LICENSE" 
				}
  s.author                      = { 
					"Nathan Douglas" => "ndouglas@devontechnologies.com" 
				}
  s.ios.deployment_target       = "9.0"
  s.osx.deployment_target       = "10.10"
  s.source                      = {
					:git => "https://github.com/ndouglas/SwiftNetService.git",
					:tag => "0.0.1"
				}
  s.subspec 'Core' do |cs|
	cs.exclude_files       	= "*Tests.swift"
	cs.source_files         = "*.swift"
	cs.framework            = "Foundation"
	cs.dependency           "ReactiveCocoa"
  end
  s.subspec 'Tests' do |ts|
	ts.source_files         = "*Tests.swift"
	ts.frameworks           = "Foundation", "XCTest"
	ts.dependency           "SwiftNetService/Core"
  end
  s.default_subspec             = "Core"
end

