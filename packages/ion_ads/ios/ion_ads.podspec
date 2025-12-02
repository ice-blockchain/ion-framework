#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ion_ads.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'ion_ads'
  s.version          = '3.10.0'
  s.summary          = 'ION Appodeal flutter plugin'
  s.description      = <<-DESC
  Flutter plugin for Appodeal SDK. It supports interstitial, rewarded video and banner ads.
  DESC
  s.homepage         = 'https://ice.io'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'ice Labs Limited' => 'hi@ice.io' }
  s.platform         = :ios, "13.0"
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'

  s.requires_arc     = true
  s.static_framework = true

  s.dependency 'Flutter'
  s.dependency "Appodeal", "3.10.0"
  s.dependency "APDIABAdapter", "3.10.0.0"

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
