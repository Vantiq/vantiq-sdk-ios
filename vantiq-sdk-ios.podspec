#
# Be sure to run `pod lib lint vantiq-sdk-ios.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "vantiq-sdk-ios"
  s.version          = "1.1.7"
  s.summary          = "API for the Vantiq system for iOS applications."
  s.description      = <<-DESC
The Vantiq iOS SDK is Objective-C that provides an API into a Vantiq system for iOS applications. The SDK connects to a Vantiq system using the Vantiq REST API.
                       DESC

  s.homepage         = "https://github.com/Vantiq/vantiq-sdk-ios"
  s.license          = 'MIT'
  s.author           = { "Vantiq, Inc." => "info@vantiq.com" }
  s.source           = { :git => "https://github.com/Vantiq/vantiq-sdk-ios.git", :tag => s.version.to_s }

  s.platform     = :ios, '9.3'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  # s.resource_bundles = {
  #   'vantiq-sdk-ios' => ['Pod/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
end
