require 'simplecov'
SimpleCov.start
require 'pry'
require 'job_reactor'

require 'stringio'
$logger_stream    ||= StringIO.new
JR::JobLogger.stdout = $logger_stream

Dir[File.expand_path('../support/*', __FILE__)].each do |f|
  require f
end