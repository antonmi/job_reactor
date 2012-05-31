Gem::Specification.new do |s|
  s.name              = "job_reactor"
  s.version           = '0.5.1'
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "Simple, powerful and high scalable job queueing and background workers system based on EventMachine"
  s.homepage          = "http://github.com/antonmi/job_reactor"
  s.email             = "anton.mishchuk@gmial.com"
  s.authors           = [ "Anton Mishchuk", "Andrey Rozhkovskiy" ]
  s.platform          = Gem::Platform::RUBY
  s.files             = %w(README.markdown)
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("examples/**/*")
  s.files            += Dir.glob("spec/**/*")
  
  s.require_path     = ['lib/job_reactor']
  #s.executables       = [ "job_reactor" ]
  
  s.add_dependency "eventmachine"
  s.add_dependency "em-redis"

  s.add_development_dependency 'redis'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'

  s.description = <<description
    JobReactor is a library for creating and processing background jobs.
    It is client-server distributed system based on EventMachine.
description
end