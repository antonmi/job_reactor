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
  JR.start_node({:storage => 'memory_storage', :name => "memory_node", :server => ['localhost', 6000], :distributors => [['localhost', 5000]] })
end


#Your application
sleep(5)
JR.enqueue('test_job', {arg1: 1, arg2: 2})
sleep(10)