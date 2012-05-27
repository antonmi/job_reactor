$: << "lib"
require 'job_reactor'
JR.config[:retry_jobs_at_start] = false
JR.config[:job_directory] = 'examples/one_distributor_three_nodes/jobs'
JR.config[:retry_multiplier] = 0

JR.run! do
  JR.start_node({:storage => 'redis_storage', :name => "redis_node", :server => ['192.168.1.3', 2001], :distributors => [['192.168.1.4', 5000]] })
end