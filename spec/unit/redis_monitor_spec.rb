require 'spec_helper'

describe 'JR::RedisMonitor' do
  ATTRS = %w(id name args last_error run_at failed_at attempt period make_after status distributor on_success on_error defer)

  before do
    @storage = Redis.new
    @hash = {
        "id" => "1338721881.4778385",
        "name" => "job",
        "args" => {:arg1 => 1},
        "last_error" => "error",
        "run_at" => "1",
        "failed_at" => "2",
        "attempt" => 1,
        "period" => 0,
        "make_after" => 0,
        "status" => "in progresss",
        "distributor" => "localhost:5000",
        "on_success" => "localhost:5000_1338721758.0794044",
        "on_error" => "localhost:5000_1338721758.0794218",
        "defer" => "false"
    }
    @node = 'test_redis_node'
    key = "#{@node}_#{@hash['id']}"
    @hash['args'] = Marshal.dump(@hash['args'])
    @storage.hmset(key, *ATTRS.map{|attr| [attr, @hash[attr]]}.flatten)
    @hash['args'] = Marshal.load(@hash['args'])
  end

  after do
    @storage.del("#{@node}_#{@hash['id']}")
  end

  describe 'redis storage' do
    it 'should return the instance of Redis' do
      JobReactor::RedisMonitor.storage.should be_an_instance_of Redis
    end
  end

  describe 'load job' do
    it 'should load job' do
      hash = JobReactor::RedisMonitor.load("#{@node}_#{@hash['id']}")
      hash.should be_an_instance_of Hash
      @hash.each do |k ,v|
        hash[k].should == v
      end
    end
  end

  describe 'jobs_for' do
    it 'should return jobs for node' do
      jobs = JobReactor::RedisMonitor.jobs_for(@node)
      jobs.should be_an_instance_of Hash
      jobs.has_key?("#{@node}_#{@hash['id']}").should be_true
      jobs["#{@node}_#{@hash['id']}"].should be_an_instance_of Hash
      jobs["#{@node}_#{@hash['id']}"].should == @hash
    end
  end

  describe 'destroy all jobs for node' do
    it 'should destroy all jobs for given node' do
      JobReactor::RedisMonitor.destroy_all_jobs_for(@node)
      @storage.keys("*#{@node}_*").should be_empty
    end
  end




end