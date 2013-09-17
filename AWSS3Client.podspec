Pod::Spec.new do |s|
  s.name     = 'AWSS3Client'
  s.version  = '0.1.3'
  s.license  = 'MIT'
  s.summary  = 'Alternative Amazon S3 client (with multipart uploading) based on AFHTTPClient.'
  s.homepage = 'https://github.com/swivl/AWSS3Client'
  s.authors  = { 'Sergei Me' => 'mer.sergei@gmail.com' }
  s.source   = { :git => 'https://github.com/swivl/AWSS3Client.git', :tag => s.version.to_s }
  s.source_files = 'AWSS3Client.{h,m}'
  s.requires_arc = true
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  s.dependency 'AFNetworking', '~> 1.3'
end
