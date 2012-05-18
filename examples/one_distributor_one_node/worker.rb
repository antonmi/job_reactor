$: << "lib"
require 'job_reactor'

JR.run! do
  JR.start_node({:storage => JobReactor::RedisStorage, :name => "redis_node", :server => ['178.159.244.149', 1500], :distributors => [['178.124.147.18', 5001]] })
end