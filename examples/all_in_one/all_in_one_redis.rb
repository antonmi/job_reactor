#The simplest direction of use.
#If you don't need to make heavy calculation, but just want to execute a bunch of background task
#In this example distributor and one node with 'redis' storage are run in one thread and use one EM reactor instance.
#Scheduled jobs are stored in Redis storage. You need to install Redis.
#To use redis storage is the best idea.
#It works asynchronously with EventMachine.
#Does not guarantee 100% persistance, but extremely fast.
#If you decide to use many working nodes with one storage, you should use Redis to feel the power!

$: << "lib"
require 'job_reactor'

#This code you should place in application initializer.
#It should be run only once
JR.run do
  JR.config[:distributor] = ['localhost', 5000] #Default option. If port is not available, distributor will increase port number
  #Job directory
  JR.config[:job_directory] = 'reactor_jobs/*.rb'
  #Default Redis host, port options
  JR.config[:redis_host] = 'localhost'
  JR.config[:redis_port] = 6379
  #Starts node in the same process
  #Node will search distributor on 'localhost:5000'
  JR.start_node({:storage => JobReactor::RedisStorage, :name => "redis_node", :server => ['localhost', 6000], :distributors => [['localhost', 5000]] })
end


#Your application
sleep(5)
JR.enqueue('test_job', {arg1: 1, arg2: 2})
sleep(10)
