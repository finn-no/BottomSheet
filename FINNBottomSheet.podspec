Pod::Spec.new do |s|
    s.name             = 'FINNBottomSheet'
    s.summary          = 'Custom modal presentation style for views anchored to the bottom of the screen'
    s.version          = '3.1.1'
    s.author           = 'FINN.no'
    s.homepage         = 'https://github.com/finn-no/bottom-sheet-ios'
    s.social_media_url = 'https://twitter.com/FINN_tech'
    s.description      = 'Simple to use and customizable modal presentation style for views anchored to the bottom of the screen.'
    s.license          = 'MIT'
    s.platform         = :ios, '11.2'
    s.requires_arc     = true
    s.swift_version    = '5.0'
    s.source           = { :git => 'https://github.com/finn-no/bottom-sheet-ios.git', :tag => s.version }
    s.cocoapods_version = '>= 1.4.0'
    s.source_files = 'Sources/*.{h,m,swift}'
    s.frameworks = 'Foundation', 'UIKit'
  end
