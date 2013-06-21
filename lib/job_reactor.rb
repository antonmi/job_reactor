require 'eventmachine'
require 'job_reactor/job_reactor'
require 'job_reactor/job_logger'
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

  def run
    Thread.new do
      if EM.reactor_running?
        yield if block_given?
        JR.ready!
      else
        EM.run do
          yield if block_given?
          JR.ready!
        end
      end
    end
  end

  def run!
    if EM.reactor_running?
      yield if block_given?
      JR.ready!
    else
      EM.run do
        yield if block_given?
        JR.ready!
      end
    end
  end

  def wait_em_and_run
    Thread.new do
      sleep(0.1) until EM.reactor_running?
      EM.schedule do
        yield if block_given?
        JR.ready!
      end
    end
  end

end
