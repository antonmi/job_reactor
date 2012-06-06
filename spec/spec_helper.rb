require 'simplecov'
SimpleCov.start

require 'job_reactor'

require 'stringio'
$logger_stream    ||= StringIO.new
JR::Logger.stdout = $logger_stream

