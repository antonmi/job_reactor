$: << "lib"
require 'job_reactor'
JR.config[:job_directory] = 'examples/two_distributors_three_nodes/jobs'

JR.run! do
  JR.start_node({:storage => 'redis_storage', :name => 'redis_node2', :server => ['localhost', 2003], :distributors => [['localhost', 5000], ['localhost', 5001]] })
end