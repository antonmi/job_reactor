require 'spec_helper'

module JobReactor
  def self.succ_feedbacks=(value)
    @@succ_feedbacks = value
  end

  def self.err_feedbacks=(value)
    @@err_feedbacks = value
  end

  module MemoryStorage
    def self.flush_storage
      @@storage = { }
    end
  end
end

describe 'simple job' do
  before :all do
    EM.stop if EM.reactor_running?
    wait_until { !EM.reactor_running? }
    JR.config[:job_directory]            = File.expand_path('../../jobs', __FILE__)
    JR.config[:merge_job_itself_to_args] = true
    JR.config[:retry_multiplier]         = 0
    JR.config[:max_attempt]              = 5
    JR.run do
      JR::Distributor.start('localhost', 5009, connect_to: ['localhost', 5009])
      JR.start_node({ storage: 'memory_storage', name: 'memory_node', server: ['localhost', 7009], connect_to: ['localhost', 7009], distributors: [['localhost', 5009]] })
    end
    wait_until { EM.reactor_running? }
  end

  describe 'simple_job with simple feedback' do
    it 'should run success feedback' do
      result  = ''
      success = proc { result = 'success' }
      JR.enqueue 'feedback', { arg1: 'arg1' }, { }, success
      wait_until(20) { result == 'success' }
      result.should == 'success'
    end

    it 'should run error feedback' do
      result = ''
      error  = proc { result = 'error' }
      JR.enqueue 'feedback_with_error', { arg1: 'arg1' }, { }, nil, error
      wait_until { result == 'error' }
      result.should == 'error'
    end
  end
end