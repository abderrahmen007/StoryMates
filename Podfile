platform :ios, '16.0'
use_frameworks!

target 'StoryMates' do
  pod 'Socket.IO-Client-Swift', '~> 16.1.0'
  pod 'ZegoUIKitPrebuiltCall'

  post_install do |installer|
    installer.generated_projects.each do |project|
      project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
          config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
        end
      end
    end
  end
end
