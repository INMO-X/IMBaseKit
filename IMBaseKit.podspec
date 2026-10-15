#
# Binary pod for the static XCFramework produced by Scripts/build_xcframeworks.sh.
# Third-party pods stay dependencies of the host. They are not vendored.
#
Pod::Spec.new do |s|
  s.name             = 'IMBaseKit'
  s.version          = '0.1.0'
  s.summary          = 'INMO X Project Base Develop Kit (static XCFramework)'
  s.description      = <<-DESC
  INMO X 项目私有基础开发套件的静态二进制。
  Kingfisher / MMKV / CryptoSwift / CocoaLumberjack / Connectivity / Moya / ObjectMapper
  由宿主工程链接同一份，不打进本 XCFramework。
                       DESC

  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'jiangqi' => 'jiangqi@inmolens.com' }
  s.homepage         = 'https://github.com/INMO-X/IMBaseKit'
  s.source           = { :git => 'https://github.com/INMO-X/IMBaseKit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.swift_version    = '5.0'
  s.static_framework = true

  s.vendored_frameworks = 'XCFrameworks/IMBaseKit.xcframework'

  s.frameworks = [
    'UIKit',
    'Foundation',
    'CoreGraphics',
    'CryptoKit',
    'CoreBluetooth',
    'CoreLocation',
    'CoreTelephony',
    'Photos',
    'PhotosUI',
    'AVFoundation',
    'Security',
    'WebKit'
  ]
  s.libraries = 'z'

  # 多语言 / 图片，以及静态链接时随 App 拷贝的隐私清单。
  # 运行时 IMLocalizedString 只在名为 IMBaseKit 的 bundle 里查表。
  s.resource_bundles = {
    'IMBaseKit' => [
      'IMBaseKit/Resources/**/*.{xcassets,lproj}',
      'IMBaseKit/Resources/PrivacyInfo.xcprivacy'
    ]
  }

  s.dependency 'Kingfisher', '8.12.0'
  s.dependency 'MMKV', '2.4.2'
  s.dependency 'CryptoSwift', '1.10.0'
  s.dependency 'CocoaLumberjack/Swift', '3.9.1'
  s.dependency 'Connectivity', '8.0.1'
  s.dependency 'Moya', '15.0.0'
  s.dependency 'ObjectMapper', '4.4.2'
end
