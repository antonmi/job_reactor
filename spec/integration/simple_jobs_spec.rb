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
    EM.stop if EM.reactor_running?
    wait_until { !EM.reactor_running? }
    ARRAY                        = []
    JR.config[:job_directory]    = File.expand_path('../../jobs', __FILE__)
    JR.config[:retry_multiplier] = 0
    JR.config[:max_attempt]      = 5
    JR.run do
      JR::Distributor.start('localhost', 5002)
      JR.start_node({ storage: 'memory_storage', name: 'memory_node', server: ['localhost', 7002], distributors: [['localhost', 5002]] })
    end
    wait_until { EM.reactor_running? }
  end

  before do
    MemoryStorage.flush_storage
    ARRAY.clear
  end

  describe 'simple_job' do

    it 'should do one simple job' do
      JR.enqueue 'simple', { arg1: 'arg1' }
      wait_until(20) { ARRAY.size == 1 }
      ARRAY.size.should == 1
      ARRAY.first[0].should == 'simple'
      ARRAY.first[1].should be_instance_of(Hash)
    end

    it 'should do 10 simple jobs' do
      10.times { JR.enqueue 'simple', { arg1: 'arg1' } }
      wait_until(10) { ARRAY.size == 10 }
      ARRAY.size.should == 10
    end
  end

  describe 'job with error' do
    it 'should retry job 5 times' do
      JR.enqueue 'simple_fail'
      wait_until { ARRAY.size == 5 }
      ARRAY.size.should == 5
      JR::MemoryStorage.storage.size.should == 1
    end
  end

  describe 'run "after" job' do
    it 'should run "after" job' do
      JR.enqueue 'simple_after', { }, { :after => 1 }
      wait_until { ARRAY.size == 1 }
      ARRAY.size.should == 1
    end

    it 'should not run "after" job immediately' do
      JR.enqueue 'simple_after', { }, { :after => 2 }
      sleep(1)
      ARRAY.size.should == 0
      wait_until { ARRAY.size != 0 }
    end
  end

  describe 'run "run_at" job' do
    it 'should run "run_at" job' do
      JR.enqueue 'simple_run_at', { }, { run_at: Time.now + 1 }
      wait_until { ARRAY.size == 1 }
      ARRAY.size.should == 1
    end

    it 'should not run "run_at" job' do
      JR.enqueue 'simple_run_at', { }, { run_at: Time.now + 2 }
      sleep(1)
      ARRAY.size.should == 0
      wait_until { ARRAY.size != 0 }
      ARRAY.size.should == 1
    end
  end

  describe 'combined options' do
    it 'should "after" with period' do
      JR.enqueue 'simple_after', { }, { after: 5, period: 3 }
      sleep(4)
      ARRAY.size.should == 0
      wait_until { ARRAY.size > 0 }
      ARRAY.size.should == 1
      wait_until { ARRAY.size > 1 }
      ARRAY.size.should == 2
    end

    it 'should not run "run_at" job' do
      JR.enqueue 'simple_run_at', { }, { run_at: Time.now + 2, period: 3 }
      sleep(1)
      ARRAY.size.should == 0
      wait_until { ARRAY.size > 0 }
      ARRAY.size.should == 1
      wait_until { ARRAY.size > 1 }
      ARRAY.size.should == 2
    end
  end
end
