require 'simplecov'
SimpleCov.start

require 'job_reactor'

require 'stringio'
$logger_stream    ||= StringIO.new
JR::Logger.stdout = $logger_stream

Dir[File.expand_path('../support/*', __FILE__)].each do |file|
  require file
end
