#
#  Be sure to run `pod spec lint NBPullToActionsController.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name             = 'NBPullToActionsController'
  s.version          = '0.0.5'
  s.summary          = 'a CocoaPods fork of NBPullToActionsController'

  s.homepage         = 'https://github.com/sunpaq/NBPullToActionsController'
  s.license          = { :type => 'BSD', :file => 'LICENSE' }
  s.author           = { 'sunpaq' => 'sunpaq@gmail.com' }
  s.source           = { :git => 'https://github.com/sunpaq/NBPullToActionsController.git', :tag => s.version.to_s }

  s.ios.deployment_target = '7.0'
  s.source_files  = "NBPullToActionsController", "NBPullToActionsController/**/*.{h,m}"
  #s.exclude_files = "Classes/Exclude"
  #s.private_header_files = ''

  #s.frameworks = 'Foundation', 'AVFoundation', 'UIKit', 'AssetsLibrary', 'CoreMedia'
  s.dependency 'Masonry', '0.6.3'
  s.dependency 'THObserversAndBinders'
  s.dependency 'ALActionBlocks', '1.0.3'

  def s.post_install(target)
    target.build_configurations.each do |config|
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
      config.build_settings['ENABLE_STRICT_OBJC_MSGSEND'] = "NO"
    end
  end
end
