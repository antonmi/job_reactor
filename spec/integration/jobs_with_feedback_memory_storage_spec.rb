require 'spec_helper'

module JobReactor
  def self.succ_feedbacks=(value)
    @succ_feedbacks = value
  end

  def self.err_feedbacks=(value)
    @err_feedbacks = value
  end

  module MemoryStorage
    def self.flush_storage
      @storage = {}
    end
  end
end

describe 'Jobs with feedback, memory storage' do
  before do
    EM.stop if EM.reactor_running?
    wait_until { !EM.reactor_running? }
    JR.config[:job_directory]            = File.expand_path('../../jobs', __FILE__)
    JR.config[:merge_job_itself_to_args] = true
    JR.config[:retry_multiplier]         = 0
    JR.config[:max_attempt]              = 5
    JR.run do
      JR.start_distributor('localhost', 5009)
      JR.start_node({ storage: 'memory_storage', name: 'memory_node', server: ['localhost', 7009], distributors: [['localhost', 5009]] })
    end
    wait_until { EM.reactor_running? }
  end

  require 'integration/shared_examples_for_jobs_with_feedbacks'
  it_behaves_like 'Jobs with feedback'

end
