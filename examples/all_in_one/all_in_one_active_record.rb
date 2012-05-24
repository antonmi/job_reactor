#The simplest direction of use.
#If you don't need to make heavy calculation, but just want to execute a bunch of background tasks
#In this example distributor and one node with active_record storage are run in one thread and use one EM reactor instance.
#Use within rails application if you prefer store your jobs in DelayedJob like style,
#if you don't want install and use Redis, and if you want 'extra' persistance.

$: << "lib"
require 'job_reactor'

#if this option is false, active_record will use your default options
JR.config[:use_custom_active_record_connection] = true
#unnecessary options if you use JobReactor with rails application
JR.config[:active_record_adapter] = 'mysql2'
JR.config[:active_record_database] = 'em'
JR.config[:active_record_user] = 'root'
JR.config[:active_record_password] = '123456'
JR.config[:active_record_table_name] = 'reactor_jobs'

#Job directory
JR.config[:job_directory] = 'examples/all_in_one/reactor_jobs'

#This code you should place in application initializer.
#It should be run only once
JR.run do
  JR::Distributor.start('localhost', 5000)
  #Starts node in the same process
  #Node will search distributor on 'localhost:5000'
  JR.start_node({:storage => JobReactor::ActiveRecordStorage, :name => "db_node", :server => ['localhost', 6000], :distributors => [['localhost', 5000]] })
end


#Your application
sleep(5)
JR.enqueue('test_job', {arg1: 1, arg2: 2})
sleep(10)

