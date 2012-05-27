$: << "lib"
require 'job_reactor'
JR.config[:retry_jobs_at_start] = false
JR.config[:job_directory] = 'examples/one_distributor_three_nodes/jobs'
JR.config[:use_custom_active_record_connection] = true
JR.config[:active_record_adapter] = 'mysql2'
JR.config[:active_record_database] = 'em'
JR.config[:active_record_user] = 'root'
JR.config[:active_record_password] = ''
JR.config[:active_record_table_name] = 'reactor_jobs'

JR.run! do
  JR.start_node({:storage => 'active_record_storage', :name => "db_node", :server => ['localhost', 2002], :distributors => [['localhost', 5000]] })
end