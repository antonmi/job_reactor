require 'spec_helper'

module JobReactor
  module MemoryStorage
    def self.flush_storage
      @@storage = { }
    end
  end
end

describe 'simple job', :slow => true do
  before do
    JR.config[:job_directory]    = File.expand_path('../../jobs', __FILE__)
    JR.config[:retry_multiplier] = 0
    JR.config[:max_attempt]      = 5
    JR.run do
      JR::Distributor.start('localhost', 5000)
      JR.start_node({ :storage => 'memory_storage', :name => 'memory_node', :server => ['localhost', 6000], :distributors => [['localhost', 5000]] })
    end
    wait_until(JR.ready?)
    JobReactor::MemoryStorage.flush_storage
  end

  after do
    if EM.reactor_running?
      JR.stop
      wait_until(!EM.reactor_running?)
    end
  end

  describe 'simple_job' do
    it 'should do one simple job' do
      JR.enqueue 'simple', { arg1: 'arg1' }, { :node => 'memory_node' }
      wait_until(ARRAY.size == 1)
      ARRAY.size.should == 1
      ARRAY.first[0].should == 'simple'
      ARRAY.first[1].should be_instance_of(Hash)
    end

    it 'should do 10 simple jobs' do
      100.times { JR.enqueue 'simple', { arg1: 'arg1' } }
      wait_until(ARRAY.size == 100)
      ARRAY.size.should == 100
    end
  end

  describe 'job with error' do
    it 'should retry job 5 times' do
      JR.enqueue 'simple_fail'
      wait_until(ARRAY.size == 5)
      ARRAY.size.should == 5
      JR::MemoryStorage.storage.size.should == 1
    end
  end

  describe 'run "after" job' do
    it 'should run "after" job' do
      JR.enqueue 'simple_after', { }, { :after => 1 }
      wait_until(ARRAY.size == 1)
      ARRAY.size.should == 1
    end

    it 'should not run "after" job immediately' do
      JR.enqueue 'simple_after', { }, { :after => 2 }
      sleep(1)
      ARRAY.size.should == 0
      wait_until(ARRAY.size > 0)
    end
  end

  describe 'run "run_at" job' do
    it 'should run "run_at" job' do
      JR.enqueue 'simple_run_at', { }, { :run_at => Time.now + 1 }
      wait_until(ARRAY.size == 1)
      ARRAY.size.should == 1
    end

    it 'should not run "run_at" job immediately' do
      JR.enqueue 'simple_run_at', { }, { :run_at => Time.now + 2 }
      sleep(1)
      ARRAY.size.should == 0
    end
  end
end
