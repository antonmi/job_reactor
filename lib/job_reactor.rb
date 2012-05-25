$LOAD_PATH.unshift 'lib/job_reactor' #TODO

puts 'loading JR'
require 'eventmachine'
require 'job_reactor/job_reactor'
require 'job_reactor/logger'
require 'job_reactor/node'
require 'job_reactor/distributor'


# JobReactor initialization process.
# Parses jobs, runs EventMachine reactor and call given block inside reactor.
# The ::run method run EM in Thread to do not prevent execution of application.
# The ::wait_em_and_run is for using JobReactor with
# applications already have EventMachine inside and run it at start. Server Thin, for example.
# The run! method is for using JobReactor as standalone application. Advanced usage. For example you wand use node with distributor in one process
#
module JobReactor
  extend self

  def run(&block)
    parse_jobs
    Thread.new do
      EM.run do
        block.call if block_given?
      end
    end
  end

  def run!(&block)
    parse_jobs
    if EM.reactor_running?
      block.call if block_given?
    else
      EM.run do
        block.call if block_given?
      end
    end
  end

  def wait_em_and_run(&block)
    parse_jobs
    Thread.new do
      sleep(1) until EM.reactor_running? #TODO better solution?
      EM.schedule do
        block.call if block_given?
      end
    end
  end
end
