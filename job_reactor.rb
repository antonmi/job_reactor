$LOAD_PATH.unshift 'lib'

puts 'loading JR'
require 'eventmachine'
require 'job_reactor'
require 'logger'
require 'node'
#require 'storages'
require 'distributor'


#JobReactor initialization process.
#The ::run method run EM in Thread to do not prevent execution of application.
#The ::wait_em_and_run is for using JobReactor with
#applications already have EventMachine inside and run it at start. Server Thin, for example.
#The run! method is for using JobReactor as standalone application. Advanced usage. For exapmle you wand use node with distibutor in on e process
#
module JobReactor
  extend self

  def run(&block)
    Thread.new do
      EM.run do
        start(&block)
      end
    end
  end

  def run!(&block)
    EM.run do
      start(&block)
    end
  end

  def wait_em_and_run(&block)
    Thread.new do
      sleep(1) until EM.reactor_running?
      start(&block)
    end
  end
end

#JR config
#need to be removed to another file

#-----------------------

Dir[JR.config[:job_directory]].each {|file| load file } #TODO Recursively load all files in folder and subfolders
puts JR.jobs


