# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'hermez' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  pod 'CocoaAsyncSocket'
  pod 'RxSwift'
  pod 'RxCocoa'
  # Pods for hermez

  target 'hermezTests' do
    inherit! :search_paths
    pod 'CocoaAsyncSocket'
    pod 'RxSwift'
    pod 'RxCocoa'
    pod 'RxBlocking'
    pod 'RxTest'
  end
  
  target 'hermez_mac' do
    platform :osx, '10.15'
    use_frameworks!
    pod 'CocoaAsyncSocket'
  end
  
  target 'hermez_macTests' do
    platform :osx, '10.15'
    pod 'CocoaAsyncSocket'
    pod 'RxBlocking'
    pod 'RxTest'
  end
  
  target 'HermezTesterCombine' do
    use_frameworks!
    pod 'CocoaAsyncSocket'
    pod 'RxSwift'
    pod 'RxCocoa'
  end
  
  target 'HermezTesterMac' do
    platform :osx, '10.15'
    use_frameworks!
    pod 'CocoaAsyncSocket'
  end
  
  target 'HermezTesterDelegate' do
    use_frameworks!
    pod 'CocoaAsyncSocket'
    pod 'RxSwift'
    pod 'RxCocoa'
  end
  
  target 'HermezTesterRx' do
    use_frameworks!
    pod 'CocoaAsyncSocket'
    pod 'RxSwift'
    pod 'RxCocoa'
  end
end
