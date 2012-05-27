require 'simplecov'
SimpleCov.start

require 'job_reactor'
#$logger_stream    ||= StringIO.new
#JR::Logger.stdout = $logger_stream

Dir[File.expand_path('../support/*', __FILE__)].each do |f|
  require f
end

RSpec.configure do |config|
  #config.filter_run_excluding :slow => true
end

