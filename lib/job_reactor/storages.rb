# Storages implement simple functionality.
# There are four methods should be implemented:
# save(hash).
# load(hash).
# destroy(hash).
# jobs_for(name).
# The last one is used when node is restarting to retry saved jobs.
# The storage may not be thread safe, because each node manage it own jobs and don't now anything about others.
require 'job_reactor/storages/active_record_storage'
require 'job_reactor/storages/memory_storage'
require 'job_reactor/storages/redis_storage'
