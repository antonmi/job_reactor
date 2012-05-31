#The simplest direction of use.
#If you don't need to make heavy calculation, but just want to execute a bunch of background tasks
#In this example distributor and one node with 'memory' storage are run in one thread and use one EM reactor instance.
#Scheduled jobs are stored in memory. They will be lost when reactor shuts down.
#But, of course, this storage is the fastest.
#Use it if have a lot of chaotic jobs and you don't want to store them

$: << 'lib'
require 'job_reactor'

#Job directory
JR.config[:job_directory] = 'examples/all_in_one/reactor_jobs'
#This code you should place in application initializer.
#It should be run only once
JR.run do
  #Starts distributor
  JR::Distributor.start('localhost', 5000)
  #Starts node in the same process
  #Node will search distributor on 'localhost:5000'
  JR.start_node({:storage => 'memory_storage', :name => 'memory_node', :server => ['localhost', 6000], :distributors => [['localhost', 5000]] })
end


#Your application
wake_up = 0

success = Proc.new do |args|
  puts 'Success'
  puts args
  wake_up += 1
end

error = Proc.new do |args|
  puts 'Error'
  puts args
end

sleep(1) until JR.ready?
JR.enqueue('test_job', {arg1: 1, arg2: 2}, {:period => 1}, success, error)
sleep(1) until wake_up > 5