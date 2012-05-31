require 'spec_helper'

module JobReactor
  module MemoryStorage
    def self.flush_storage
      @@storage = { }
    end
  end
end

describe 'simple job', :slow => true do
  before :all do
    JR.config[:job_directory]    = File.expand_path('../../jobs', __FILE__)
    JR.config[:merge_job_itself_to_args] = true
    JR.config[:retry_multiplier] = 0
    JR.config[:max_attempt]      = 5
    JR.run do
      JR::Distributor.start('localhost', 5001)
      JR.start_node({ :storage => 'memory_storage', :name => 'memory_node', :server => ['localhost', 7001], :distributors => [['localhost', 5001]] })
    end
    wait_until(JR.ready?)
  end

  describe 'simple_job with simple feedback' do
    it 'should run success feedback' do
      result = ''
      success = proc { result = 'success' }
      JR.enqueue 'feedback', {arg1: 'arg1'}, {}, success
      wait_until result == 'success'
      result.should == 'success'
    end

    it 'should run error feedback' do
      result = ''
      error = proc { result = 'error' }
      JR.enqueue 'feedback_with_error', {arg1: 'arg1'}, {}, nil, error
      wait_until result == 'error'
      result.should == 'error'
    end
  end

  describe 'simple_job with feedback' do
    it 'should run success feedback' do
      result = ''
      success = proc { |args| result = args }
      JR.enqueue 'feedback', {arg1: 'arg1'}, {}, success
      wait_until(result != '')
      result.class.should == Hash
      result[:arg1].should == 'arg1'
    end

    it 'should run error feedback' do
      result = ''
      error = proc { |args| result = args }
      JR.enqueue 'feedback_with_error', {arg1: 'arg1'}, {}, nil, error
      wait_until result != ''
      result.class.should == Hash
      result[:arg1].should == 'arg1'
      result[:error].class.should == NameError
    end
  end

  describe 'feedback_args' do
    it 'should run success feedback with :result => "ok"' do
      result = ''
      success = proc { |args| result = args }
      JR.enqueue 'feedback', {arg1: 'arg1'}, {}, success
      wait_until(result != '')
      result.class.should == Hash
      result[:result].should == 'ok'
    end

    it 'should has job_itself in args' do
      result = ''
      success = proc { |args| result = args }
      JR.enqueue 'feedback', {arg1: 'arg1'}, {}, success
      wait_until(result != '')
      result.class.should == Hash
      result[:job_itself].class == Hash
      %w(name args attempt status make_after distributor on_success node run_at).each do |key|
        result[:job_itself].keys.include?(key).should be_true
      end
    end

  end

end
