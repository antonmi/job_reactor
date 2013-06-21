require 'spec_helper'

module JobReactor
  def self.succ_feedbacks=(value)
    @succ_feedbacks = value
  end

  def self.err_feedbacks=(value)
    @err_feedbacks = value
  end

  module RedisStorage
    def self.nil_storage
      @storage = nil
    end
  end
end

describe 'Jobs with feedback, redis storage' do
  before do
    if EM.reactor_running?
      if defined?(JR::RedisStorage.storage)
        JR::RedisStorage.storage.close_connection
        wait_until { !JR::RedisStorage.storage.connected? }
        JR::RedisStorage.nil_storage
      end
      EM.stop
      wait_until { !EM.reactor_running? }
    end
    JR.config[:job_directory]            = File.expand_path('../../jobs', __FILE__)
    JR.config[:merge_job_itself_to_args] = true
    JR.config[:retry_multiplier]         = 0
    JR.config[:max_attempt]              = 5
    JR.run do
      JR.start_distributor('localhost', 5009)
      JR.start_node({ storage: 'redis_storage', name: 'redis_node', server: ['localhost', 7009], distributors: [['localhost', 5009]] })
    end
    wait_until { EM.reactor_running? }
    wait_until(3, true) { defined?(JR::RedisStorage.storage) && JR::RedisStorage.storage.connected? }
  end

  require 'integration/shared_examples_for_jobs_with_feedbacks'
  it_behaves_like 'Jobs with feedback'

end
