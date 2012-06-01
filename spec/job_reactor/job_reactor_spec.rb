require 'spec_helper'
require 'eventmachine'

describe JobReactor do

  describe 'parse_jobs' do
    JobReactor.config[:job_directory] = File.expand_path("../../jobs", __FILE__)
    JobReactor.send(:parse_jobs)
    it 'jobs returns hash' do
      JobReactor.jobs.should be_instance_of Hash
    end
    it 'should have key "test_job"' do
      JobReactor.jobs.keys.include?('test_job').should be_true
    end
    it 'should have job, callbacks and errbacks' do
      (JobReactor.jobs['test_job'].keys - [:job, :callbacks, :errbacks]).should == []
    end
    it 'job should be Proc' do
      JobReactor.jobs['test_job'][:job].should be_instance_of Proc
    end
  end

  describe 'start_node' do
    before do
      @opts = { :storage => 'memory_storage', :name => 'memory_node', :server => ['localhost', 6000], :distributors => [['localhost', 5000]] }
      Node.any_instance.stub(:start).and_return(true)
    end

    it 'should require memory_storage' do
      JobReactor.should_receive(:require).with('job_reactor/storages/memory_storage')
      JR.start_node(@opts)
    end

    it 'should call start method on node' do
      Node.any_instance.should_receive(:start)
      JR.start_node(@opts)
    end

    it 'should change opts[:storage]' do
      JR.start_node(@opts)
      @opts[:storage].should == JobReactor::MemoryStorage
    end
  end

  describe 'enqueue job' do
    before do
      EM.stub(:start_server).and_return(true)
      JobReactor.start_distributor('localhost', '3000')
      JobReactor.config[:job_directory] = File.expand_path("../../jobs", __FILE__)
      JobReactor::Distributor.stub(:send_data_to_node).and_return(true)
    end

    it 'should enqueue simple job' do
      hash = { 'name' => 'test_job', 'args' => {}, 'attempt' => 0, 'status' => 'new', 'make_after' => 0, 'distributor' => 'localhost:3000' }
      JobReactor::Distributor.should_receive(:send_data_to_node).with(hash)
      JR.enqueue('test_job')
    end

    it 'should enqueue job with args' do
      hash = { 'name' => 'test_job', 'args' => {a: 1, b: 2}, 'attempt' => 0, 'status' => 'new', 'make_after' => 0, 'distributor' => 'localhost:3000' }
      JobReactor::Distributor.should_receive(:send_data_to_node).with(hash)
      JR.enqueue('test_job', { a: 1, b: 2 })
    end

    it 'should enqueue "after" job with args' do
      hash = { 'name' => 'test_job', 'args' => {a: 1, b: 2}, 'attempt' => 0, 'status' => 'new', 'make_after' => 1, 'distributor' => 'localhost:3000' }
      JobReactor::Distributor.should_receive(:send_data_to_node).with(hash)
      JR.enqueue('test_job', { a: 1, b: 2 }, { after: 1 })
    end

    #TODO
    #it 'should enqueue "run_at" with args' do
    #  hash = { 'name' => 'test_job', 'args' => {a: 1, b: 2}, 'attempt' => 0, 'status' => 'new', 'make_after' => 1 }
    #  JobReactor::Distributor.should_receive(:send_data_to_node).with(hash)
    #  JR.enqueue('test_job', { a: 1, b: 2 }, { run_at: Time.now + 1 })
    #end

    it 'should enqueue "periodic" job with args' do
      hash = { 'name' => 'test_job', 'args' => {a: 1, b: 2}, 'attempt' => 0, 'status' => 'new', 'make_after' => 0, 'period' => 5, 'distributor' => 'localhost:3000' }
      JobReactor::Distributor.should_receive(:send_data_to_node).with(hash)
      JR.enqueue('test_job', { a: 1, b: 2 }, { period: 5 })
    end

    it 'should enqueue job for specific node' do
      hash = { 'name' => 'test_job', 'args' => {a: 1, b: 2}, 'attempt' => 0, 'status' => 'new', 'make_after' => 0, 'node' => 'A', 'not_node' => 'B', 'distributor' => 'localhost:3000' }
      JobReactor::Distributor.should_receive(:send_data_to_node).with(hash)
      JR.enqueue('test_job', { a: 1, b: 2 }, { node: 'A', not_node: 'B' })
    end
  end

  describe 'make job' do
    before do
      @hash = {'name' => 'test_job'}
    end

    it 'should receive 2 callbacks' do
      JR.config[:log_job_processing] = false
      @hash.should_receive(:callback).exactly(2)
      JobReactor.make(@hash)
    end

    it 'should receive 4 callbacks' do
      JR.config[:log_job_processing] = true
      @hash.should_receive(:callback).exactly(4)
      JobReactor.make(@hash)
    end

    it 'JR should receive add_callback' do
      JR.config[:log_job_processing] = true
      JobReactor.should_receive(:add_start_callback)
      JobReactor.should_receive(:add_last_callback)
      JobReactor.make(@hash)
    end

    it 'should receive 1 errback' do
      JR.config[:log_job_processing] = false
      @hash.should_receive(:errback).exactly(1)
      JobReactor.make(@hash)
    end

    it 'should receive 3 errback' do
      JR.config[:log_job_processing] = true
      @hash.should_receive(:errback).exactly(3)
      JobReactor.make(@hash)
    end

    it 'JR should receive add_start_errback and add_complete_errback' do
      JR.config[:log_job_processing] = true
      JobReactor.should_receive(:add_start_errback)
      JobReactor.should_receive(:add_complete_errback)
      JobReactor.make(@hash)
    end
  end
end