#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint abto_voip_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'abto_voip_sdk'
  s.version          = '0.0.1'
  s.summary          = 'Abto VoIP Flutter SDK'
  s.description      = <<-DESC
Abto VoIP Flutter SDK
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'AbtoVoipSDK.h'
  s.frameworks = 'SystemConfiguration', 'CoreMedia', 'CoreGraphics', 'UIKit', 'Accelerate', 'AudioToolbox', 'AVFoundation', 'Foundation', 'AbtoSipClientWrapper'
  s.vendored_frameworks = 'AbtoSipClientWrapper.xcframework'
  s.preserve_paths = 'Classes/AbtoVoipSDK.{h,m}'
  s.resources = 'AbtoSipClientWrapper/Resources/*.{wav,mp3,caf}'
  s.libraries = 'c++', 'z'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386', 'ENABLE_BITCODE' => 'NO' }
  s.user_target_xcconfig = { 'ENABLE_BITCODE' => 'NO' }
  s.swift_version = '5.0'
end
