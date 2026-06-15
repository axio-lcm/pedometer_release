Pod::Spec.new do |s|
  s.name             = 'pedometer_health'
  s.version          = '0.1.0'
  s.summary          = 'Local health sync plugin for the pedometer app.'
  s.description      = <<-DESC
Local Flutter plugin for reading Apple Health summaries.
                       DESC
  s.homepage         = 'https://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Pedometer' => 'dev@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.swift_version = '5.0'
  s.frameworks = 'HealthKit'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
