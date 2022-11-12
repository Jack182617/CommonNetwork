#
# Be sure to run `pod lib lint CommonNetwork.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CommonNetwork'
  s.version          = '0.6.0'
  s.summary          = 'A short description of CommonNetwork.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Jack182617/CommonNetwork'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '550936272@qq.com' => '550936272@qq.com' }
  s.source           = { :git => 'https://github.com/Jack182617/CommonNetwork.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.source_files = 'CommonNetwork/Classes/**/*'
  
  # s.resource_bundles = {
  #   'CommonNetwork' => ['CommonNetwork/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'

  s.dependency 'Moya', '15.0.0'
  s.dependency 'HandyJSON', '5.0.2'
  s.dependency 'ProgressHUD', '2.70'
  s.dependency 'Toast-Swift', '5.0.1'
end
