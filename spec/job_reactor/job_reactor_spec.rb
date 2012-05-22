require 'spec_helper'
require 'job_reactor'

module JobReactor
  describe JobReactor do

    describe 'parse_jobs' do
      JobReactor.config[:job_directory] = File.expand_path("../../../spec/jobs", __FILE__)
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





  end
end