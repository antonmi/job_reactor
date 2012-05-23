$: << "lib"
require 'job_reactor'

JR.run! do
  JR.config[:job_directory] = 'examples/one_distributor_three_nodes/jobs'
  JR.start_node({:storage => JobReactor::RedisStorage, :name => "redis_node3", :server => ['localhost', 2003], :distributors => [['localhost', 5000]] })
end