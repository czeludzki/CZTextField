#
# Be sure to run `pod lib lint CZTextField.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CZTextField'
  s.version          = '0.1.3'
  s.summary          = 'An textfield with animated placeholders'

  s.description      = 'An textfield with animated placeholders.'

  s.homepage         = 'https://github.com/czeludzki/CZTextField'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'czeludzki' => 'czeludzki@gmail.com' }
  s.source           = { :git => 'https://github.com/czeludzki/CZTextField.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'CZTextField/Classes/**/*'

  s.frameworks = 'UIKit'
  s.dependency 'Masonry'
end
