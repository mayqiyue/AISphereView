#
# Be sure to run `pod lib lint AISphereView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AISphereView'
  s.version          = '1.0.4'
  s.summary          = 'AISphereView is great.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = ""

  s.homepage         = 'https://github.com/mayqiyue/AISphereView'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'mayqiyue' => 'xu20121013@gmail.com' }
  s.source           = { :git => 'https://github.com/mayqiyue/AISphereView.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'AISphereView/Classes/**/*'
   s.frameworks = 'UIKit'
end
