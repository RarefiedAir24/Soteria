# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'soteria' do
  # Use dynamic frameworks - but LinkKit will be lazy-loaded to prevent dyld crash
  use_frameworks!

  # Firebase (already added via SPM, but keeping for reference)
  # Firebase is managed via Swift Package Manager
  
  # Plaid Link SDK for bank account connection
  # Upgraded to v4.1+ (v3.1.1 is not supported on modern iOS/Xcode)
  # Added NSCameraUsageDescription to Info.plist (required by Plaid)
  # Let CocoaPods manage all framework embedding - do NOT manually embed in Xcode
  pod 'Plaid', '~> 4.1'

  target 'SoteriaMonitor' do
    # Extension target - no additional pods needed
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      # Fix for XCFramework sandbox issues - still needed for dynamic frameworks
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
  end
  
  # Let CocoaPods fully manage LinkKit embedding - no manual modifications needed
  # Removed all custom hooks that modified LinkKit embedding per Plaid support guidance
end
