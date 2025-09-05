#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ion_content_labeler.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'ion_content_labeler'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin to label the provided content'
  s.description      = <<-DESC
The plugin might be used to analyze the input text and produce corresponding labels, such as the detected language and content categories
                       DESC
  s.homepage         = 'https://ice.io'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'ice Labs Limited' => 'hi@ice.io' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files     = ''
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  s.vendored_frameworks = 'Frameworks/fasttext_predict.xcframework'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }

  s.swift_version = '5.0'
end
