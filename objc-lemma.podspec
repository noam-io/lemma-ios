#
# Be sure to run `pod spec lint objc-lemma.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# To learn more about the attributes see http://docs.cocoapods.org/specification.html
#
Pod::Spec.new do |s|
  s.name         = "objc-lemma"
  s.version      = "0.1.1"
  s.summary      = "Objective-C Noam lemma implementation."
  s.homepage     = "https://github.com/ideo/obj-c-noam-lemma"
  s.license      = 'MIT'
  s.author       = { "Tim Shi" => "timshi@ideo.com" }
  s.source       = { :git => "https://github.com/ideo/obj-c-noam-lemma.git", :tag => s.version.to_s }
  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.7'
  s.source_files = 'NoamLemma/'
  s.requires_arc = true
  s.dependency 'SocketRocket'
  s.dependency 'CocoaAsyncSocket'
end
