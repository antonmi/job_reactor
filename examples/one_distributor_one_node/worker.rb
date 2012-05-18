$: << "lib"
require 'job_reactor'

JR.run! do
  JR.start_node({:storage => JobReactor::RedisStorage, :name => "redis_node", :server => ['192.168.1.3', 6001], :distributors => [['192.168.1.3', 5001]] })
end