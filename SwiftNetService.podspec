Pod::Spec.new do |s|
  s.name         		= "SwiftNetService"
  s.version      		= "1.0.4"
  s.summary      		= "A simple microframework for handling Bonjour services fluidly and reactively."
  s.description  		= <<-DESC
                   		DESC
  s.homepage     		= "https://github.com/ndouglas/SwiftNetService"
  s.license      		= { :type => "Public Domain", :file => "LICENSE" }
  s.author             		= { "Nathan Douglas" => "github@tenesm.us" }
  s.ios.deployment_target 	= "9.0"
  s.osx.deployment_target 	= "10.10"
  s.source       		= { :git => "https://github.com/ndouglas/SwiftNetService.git", :tag => "1.0.4" }
  s.exclude_files		= "SwiftNetService/*Tests.swift"
  s.source_files		= "SwiftNetService/*.swift"
  s.public_header_files 	= "SwiftNetService/SwiftNetService.h"
  s.framework			= "Foundation"
  s.dependency			"SwiftAssociatedObjects"
  s.dependency			"ReactiveCocoa"
  s.requires_arc		= true
end
