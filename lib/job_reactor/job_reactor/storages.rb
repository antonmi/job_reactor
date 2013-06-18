# Storages implement simple functionality.
# There are four methods should be implemented:
# save(hash).
# load(hash).
# destroy(hash).
# jobs_for(name). The method is called when node starts.
# The last one is used when node is restarting to retry saved jobs.
# The storage may not be thread safe, because each node manage it own jobs and don't now anything about others.

# Defines storages for lazy loading

module JobReactor::MemoryStorage; end
module JobReactor::RedisStorage; end

module JobReactor
  STORAGES = {
      'memory_storage' => JobReactor::MemoryStorage,
      'redis_storage' => JobReactor::RedisStorage
  }
end
