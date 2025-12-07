# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'soteria' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Firebase (already added via SPM, but keeping for reference)
  # Firebase is managed via Swift Package Manager

  target 'ReverMonitor' do
    # Extension target - no additional pods needed
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end

