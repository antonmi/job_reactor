Gem::Specification.new do |s|
  s.name              = 'job_reactor'
  s.version           = '0.5.1'
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = 'Simple, powerful and high scalable job queueing and background workers system based on EventMachine'
  s.homepage          = 'http://github.com/antonmi/job_reactor'
  s.email             = 'anton.mishchuk@gmial.com'
  s.authors           = [ "Anton Mishchuk", "Andrey Rozhkovskiy" ]
  s.platform          = Gem::Platform::CURRENT

  s.files             = Dir["lib/**/*.rb"]
  s.files             += Dir['README.markdown']
  s.files.delete('lib/job_reactor/storages/active_record_storage.rb')

  s.require_path     = 'lib'

  s.add_dependency 'eventmachine'
  s.add_dependency 'em-redis'

  s.description = <<description
    JobReactor is a library for creating and processing background jobs.
    It is client-server distributed system based on EventMachine.
description
end