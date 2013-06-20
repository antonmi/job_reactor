require 'spec_helper'
require 'job_reactor/storages/redis_monitor'

describe 'Redis storage' do

  before do
    @job = { 'node' => 'redis', 'name' => 'test_job', 'args' => 'args'}
    JR::RedisMonitor.destroy_all_jobs_for('redis')
    Thread.new do
      EM.run do
        require 'job_reactor/storages/redis_storage'
      end unless EM.reactor_running?
    end

    wait_until(1, true) { defined?(JR::RedisStorage.storage) && JR::RedisStorage.storage.connected? }
  end

  it 'should save job' do
    JR::RedisStorage.save(@job) do |hash|
      @saved_job = JR::RedisMonitor.jobs_for('redis').values.first
      expect(@saved_job['name']).to eq('test_job')
      expect(@saved_job['args']).to eq('args')
    end
    wait_until(1, true) { @saved_job }
  end

  it 'should save job and call the block' do
    JR::RedisStorage.save(@job) do |hash|
      @hash = hash
      expect(@hash).to_not be_nil
    end
    wait_until(1, true) { @hash }
  end

  it 'should load job' do
    JR::RedisStorage.save(@job) do |hash|
      JR::RedisStorage.load(hash) do |hash|
        @hash = hash
        expect(@hash['name']).to eq('test_job')
        expect(@hash['args']).to eq('args')
      end
    end
    wait_until(1, true) { @hash }
  end

  it 'should destroy job' do
    JR::RedisStorage.save(@job) do |hash|
      JR::RedisStorage.destroy(hash) do |hash|
        @hash = hash
        expect(JR::RedisMonitor.jobs_for('redis')).to be_empty?
      end
    end
    wait_until(1, true) { @hash }
  end

end