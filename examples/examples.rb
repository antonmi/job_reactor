$: << Dir.pwd

require 'lib/job_reactor'
JR.run! do
  #JR.config[:distributor] = ['localhost', 5000]


  JR.start_node({:storage => JobReactor::RedisStorage, :name => "redis_node", :server => ['localhost', 6015], :distributors => [['localhost', 5000]] })

  #require 'lib/storages/memory_storage'
  #JR.start_node({:storage => JobReactor::MemoryStorage, :name => "memory_node", :server => ['localhost', 6015], :distributors => [['localhost', 5000]] })

  #require 'lib/storages/active_record_storage'
  #JR.start_node({:storage => JobReactor::ActiveRecordStorage, :name => "db_node", :server => ['localhost', 6015], :distributors => [['localhost', 5000]] })
  sleep(10)
   JR.enqueue('create', {arg1: 1, arg2: 2})
end


loop do

end
