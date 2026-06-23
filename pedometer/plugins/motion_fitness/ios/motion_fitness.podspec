Pod::Spec.new do |s|
  s.name             = 'motion_fitness'
  s.version          = '0.1.0'
  s.summary          = 'Motion fitness authorization and step counting.'
  s.description      = <<-DESC
Local Flutter plugin for Core Motion / Android step counter data.
                       DESC
  s.homepage         = 'https://example.com'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Pedometer' => 'pedometer@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'
  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
