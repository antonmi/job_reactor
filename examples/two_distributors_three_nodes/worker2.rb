$: << "lib"
require 'job_reactor'
JR.config[:retry_jobs_at_start] = false
JR.config[:job_directory] = 'examples/two_distributors_three_nodes/jobs'

JR.run! do
  JR.start_node({:storage => 'redis_storage', :name => 'redis_node1', :server => ['localhost', 2002], :distributors => [['localhost', 5000], ['localhost', 5001]] })
end