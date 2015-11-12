use_frameworks!
inhibit_all_warnings!

def shared_pods
	pod 'ReactiveCocoa', :path=>'../ReactiveCocoa/ReactiveCocoa.podspec.json'
	pod 'SwiftAssociatedObjects', :git->'https://github.com/ndouglas/SwiftAssociatedObjects'
end

target 'SwiftNetService-Mac' do
	shared_pods
end

target 'SwiftNetServiceTests-Mac' do

end

target 'SwiftNetService-iOS' do
	shared_pods
end

target 'SwiftNetServiceTests-iOS' do
	
end

