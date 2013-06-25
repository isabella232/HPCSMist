Pod::Spec.new do |s|
  s.name         = "HPCSMist"
  s.version      = "0.0.7"
  s.summary      = "A delightful networking interface to HP Cloud Services inspired by AFNetworking ."
  s.homepage     = "https://github.com/hpcloud/HPCSMist"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Mike Hagedorn" => "mike.hagedorn@hp.com" }
  s.source       = { :git => "https://gitihub.com/hpcloud/HPCSMist", :tag => "0.0.6"  }
  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.7'
  s.source_files = 'Classes/Models/**/*.{h,m}'
  s.requires_arc = true
  s.frameworks =  "Security"
  s.dependency 'AFNetworking'
end
