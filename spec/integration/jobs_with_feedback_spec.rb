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

describe 'simple job' do
  before :all do
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

  describe 'simple_job with feedback' do
    it 'should run success feedback' do
      result  = ''
      success = proc { |args| result = args }
      JR.enqueue 'feedback', { arg1: 'arg1' }, { }, success
      wait_until { result.is_a?(Hash) }
      result.class.should == Hash
      result[:arg1].should == 'arg1'
    end

    it 'should run error feedback' do
      result = ''
      error  = proc { |args| result = args }
      JR.enqueue 'feedback_with_error', { arg1: 'arg1' }, { }, nil, error
      wait_until { result.class == Hash }
      result.class.should == Hash
      result[:arg1].should == 'arg1'
      result[:error].class.should == NameError
    end
  end

  describe 'feedback_args' do
    it 'should run success feedback with :result => "ok"' do
      result  = nil
      success = proc { |args| result = args }
      JR.enqueue 'feedback', { arg1: 'arg1' }, { }, success
      wait_until { result.class == Hash }
      result.class.should == Hash
      result[:result].should == 'ok'
    end

    it 'should has job_itself in args' do
      result  = nil
      success = proc { |args| result = args }
      JR.enqueue 'feedback', { arg1: 'arg1' }, { }, success
      wait_until { result.class == Hash }
      result.class.should == Hash
      result[:job_itself].class == Hash
      %w(name args attempt status make_after distributor on_success node run_at).each do |key|
        result[:job_itself].keys.include?(key).should be_true
      end
    end
  end

  describe 'feedbacks for periodic job' do
    it 'should run feedbacks several times' do
      JR.succ_feedbacks = { }
      result            = []
      success           = proc { |args| result << args }
      JR.enqueue 'feedback', { arg1: 'arg1' }, { :period => 5 }, success
      wait_until(3) { result.size == 1 }
      result.size.should == 1
      JR.succ_feedbacks.size.should == 1
      wait_until(5) { result.size == 2 }
      result.size.should == 2
    end

    it 'should run success feedback when job is cancelled' do
      JR.succ_feedbacks = { }
      result            = []
      success           = proc { |args| result << args }
      JR.enqueue 'will_cancel', { arg: 1 }, { period: 2 }, success
      wait_until(10) { result.size == 3 }
      result.size.should == 3
    end

    it 'should run error feedback when job is cancelled' do
      JR.err_feedbacks = { }
      result           = []
      error            = proc { |args| result << args }
      JR.enqueue 'will_cancel_in_errback', { arg: 1 }, { period: 2 }, { }, error
      wait_until(6) { result.size == 1 }
      result.size.should == 1
      result.first[:error].should be_an_instance_of NameError
    end

  end

  context 'defer job' do
    describe 'feedbacks for periodic job' do
      it 'should run feedbacks several times' do
        JR.succ_feedbacks = { }
        result            = []
        success           = proc { |args| result << args }
        JR.enqueue 'feedback', { arg1: 'arg1' }, { period: 5, defer: true }, success
        wait_until(3) { result.size == 1 }
        result.size.should == 1
        JR.succ_feedbacks.size.should == 1
        wait_until(5) { result.size == 2 }
        result.size.should == 2
      end

      it 'should run success feedback when job is cancelled' do
        JR.succ_feedbacks = { }
        result            = []
        success           = proc { |args| result << args }
        JR.enqueue 'will_cancel', { arg: 1 }, { period: 2, defer: true }, success
        wait_until(10) { result.size == 3 }
        result.size.should == 3
      end

      it 'should run error feedback when job is cancelled' do
        JR.err_feedbacks = { }
        result           = []
        error            = proc { |args| result << args }
        JR.enqueue 'will_cancel_in_errback', { arg: 1 }, { period: 2, defer: true }, { }, error
        wait_until(6) { result.size == 1 }
        result.size.should == 1
        result.first[:error].should be_an_instance_of NameError
      end

    end
  end

end
