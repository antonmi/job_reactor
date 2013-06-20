require 'spec_helper'

describe 'simple job, redis storage', slow: true do
  before :all do
    EM.stop if EM.reactor_running?
    wait_until { !EM.reactor_running? }
    ARRAY = [] unless defined? ARRAY
    JR.config[:job_directory] = File.expand_path('../../jobs', __FILE__)
    JR.config[:retry_multiplier] = 0
    JR.config[:max_attempt] = 5
    JR.run do
      JR.start_distributor('localhost', 5009)
      JR.start_node({ storage: 'redis_storage', name: 'redis_node', server: ['localhost', 7009], distributors: [['localhost', 5009]] })
    end
    wait_until(1, true) { defined?(JR::RedisStorage.storage) && JR::RedisStorage.storage.connected? }
  end

  before do
    ARRAY.clear
    JR::RedisMonitor.destroy_all_jobs_for('redis_node')
  end

  require 'integration/shared_examples_for_simple_jobs'
  it_behaves_like 'Simple Jobs'

end
