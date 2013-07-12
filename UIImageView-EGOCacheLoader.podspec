Pod::Spec.new do |s|
  s.name            = 'UIImageView-EGOCacheLoader'
  s.author          = { "Dmitry Ponomarev" => "demdxx@gmail.com" }
  s.version         = '0.0.0'
  s.license         = 'MIT'
  s.summary         = 'UIImageView cache using EGOCache and AFNetworking'
  s.homepage        = 'https://github.com/demdxx/UIImageView-EGOCacheLoader'
  s.source          = {:git => 'https://github.com/demdxx/UIImageView-EGOCacheLoader.git', :tag => 'v0.0.0'}

  s.platform        = :ios
  
  s.source_files    = '*.{h,m}'
  s.requires_arc    = false
  
  s.ios.frameworks  = 'Foundation', 'UIKit'
  
  # s.dependency 'NSHelpers', '>= 0.0.2'
  s.dependency 'EGOCache', '~> 2.0'
  s.dependency 'AFNetworking', '~> 1.3.0'
end
