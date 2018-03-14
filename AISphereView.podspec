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

  s.description      = <<-DESC
  I like to realize UI effects when I am free. The AISphereView was inspire by QQ Browser(https://itunes.apple.com/cn/app/qq%E6%B5%8F%E8%A7%88%E5%99%A8-%E5%BD%95%E8%A7%86%E9%A2%91%E7%A7%80%E5%87%BA%E4%BD%A0%E7%9A%84%E7%B2%BE%E5%BD%A9%E7%9E%AC%E9%97%B4/id370139302?mt=8).
  DESC

  s.homepage         = 'https://github.com/mayqiyue/AISphereView'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'mayqiyue' => 'xu20121013@gmail.com' }
  s.source           = { :git => 'https://github.com/mayqiyue/AISphereView.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'AISphereView/Classes/**/*'
   s.frameworks = 'UIKit'
end
