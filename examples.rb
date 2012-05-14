$: << Dir.pwd
require 'job_reactor'

JR.run do
  JR.config[:distributor] = ['localhost', 5000]

  #require 'lib/storages/redis_storage' #TODO Need to be required inside reactor
  #JR.start_node({:storage => JobReactor::RedisStorage, :name => "redis_node", :server => ['localhost', 6015], :distributors => [['localhost', 5000]] })

  #require 'lib/storages/memory_storage'
  #JR.start_node({:storage => JobReactor::MemoryStorage, :name => "memory_node", :server => ['localhost', 6015], :distributors => [['localhost', 5000]] })

  require 'lib/storages/active_record_storage'
  JR.start_node({:storage => JobReactor::ActiveRecordStorage, :name => "db_node", :server => ['localhost', 6015], :distributors => [['localhost', 5000]] })

end


loop do
  sleep(5)
  JR.enqueue('create', {arg1: 1, arg2: 2})
end
