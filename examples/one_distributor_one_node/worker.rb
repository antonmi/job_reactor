$: << "lib"
require 'job_reactor'

JR.run! do
  JR.start_node({:storage => JobReactor::RedisStorage, :name => "redis_node", :server => ['10.1.27.109', 2000], :distributors => [['178.124.147.18', 5001]] })
end