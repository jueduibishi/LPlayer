

Pod::Spec.new do |spec|

  
  spec.name         = "LPlayer"
  spec.version      = "0.0.2"
  spec.summary      = "一个基础的音频、视频播放器."

  
  spec.description  = <<-DESC
    一个基础的音频、视频播放器
                   DESC

  spec.homepage     = "https://github.com/jueduibishi/LPlayer"
  
   spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }


  

  spec.author             = { "yangyifan" => "yangyifan@4399inc.com" }
  
spec.ios.deployment_target = '12.0'
spec.swift_version = '5.0'

 

  spec.source       = { :git => "https://github.com/jueduibishi/LPlayer.git", :tag => "#{spec.version}" }


 
  spec.source_files = "LPlayerDemo/LPlayerDemo/classes/**/*.swift"
  
  # 如果LPlayer包含资源文件（如图片、xib等），需要额外指定资源文件路径
   spec.resource_bundles = {
     'LPlayer' => ['LPlayerDemo/LPlayerDemo/classes/cover.bundle/**/*']
   }
  
  #spec.exclude_files = "Classes/Exclude"

  # spec.public_header_files = "Classes/**/*.h"


end
