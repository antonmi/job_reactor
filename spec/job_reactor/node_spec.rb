require 'spec_helper'

def options
  { storage: 'storage', name: 'name', server: 'server', distributors: ['distributors'] }
end

describe JobReactor::Node do
  subject { JobReactor::Node.new(options) }
  describe '.initialize' do
    options.keys.each do |option|
      it("should set #{option}") { subject.config[option].should == options[option] }
    end
  end

  describe 'options attr_readers' do
    options.keys.each do |option|
      it { should respond_to(option) }
    end
  end

  describe '.start' do
    before do
      subject.stub(:retry_jobs)
      EM.stub(:start_server)
      subject.stub(:connect_to)
    end
    it "should retry_jobs" do
      subject.should_receive(:retry_jobs)
      subject.start
    end
    it "should start EM server" do
      EM.should_receive(:start_server)
      subject.start
    end
    it "should try to connect to each distributor given" do
      subject.should_receive(:connect_to).exactly(options[:distributors].size).times
      subject.start
    end
  end

  describe '.connect_to' do
    context 'with existing connection' do
      before do
        fake_connection = double('fake_connection')
        fake_connection.should_receive(:reconnect)
        subject.instance_variable_set(:@connections, { connect1: fake_connection })
      end
      it "should reconnect to distributor" do
        subject.connect_to(:connect1)
      end
    end
    context 'without existing connection' do
      before { EM.should_receive(:connect).and_return('success') }
      it "should connect to distributor" do
        subject.connect_to(:connect1)
        subject.connections.should have_key(:connect1)
      end
    end
  end

  describe '#do_job' do
    let(:storage) { double('storage') }
    let(:job) { { 'storage' => storage, 'args' => { } } }
    before do
      storage.stub(:save)
      subject.config.merge!( :storage => storage )
    end
    context 'independently on result' do
      before { subject.send(:do_job, job) }
      it("should set 'run_at'") { job['run_at'].should be }
      it("should set 'status'") { job['status'].should be }
    end
    context 'when job succeeds' do
      before do
        storage.stub(:save).and_yield(job)
        storage.stub(:destroy)
        job.stub(:succeed)
      end
      it("should call succeed on job") do
        job.should_receive(:succeed)
        subject.send(:do_job, job)
      end
      context 'with :remove_done_jobs => true' do
        before do
          JR.config[:remove_done_jobs] = true
          job['storage'].should_receive(:destroy)
          subject.send(:do_job, job)
        end
        it("should be destroyed") {  }
      end
      context 'with :remove_done_jobs => false' do
        before do
          JR.config[:remove_done_jobs] = false
          storage.stub(:save) {|&block| block.call(job) if block}
        end
        it("should set status to complete") do
          subject.send(:do_job, job)
          job['status'].should == 'complete'
        end
        it "should save job to storage" do
          storage.should_receive(:save).at_least(2).times {|job, &block| block.call(job) if block}
          subject.send(:do_job, job)
        end
      end
      context 'for periodic job' do
        before do
          job['period'] = 10
          subject.stub(:schedule)
        end
        context '' do
          before { subject.send(:do_job, job) }
          it("should set status to 'queued'") { job['status'].should == 'queued' }
          it("should set make_after to period") { job['make_after'].should == job['period'] }
        end
        it("should save job") do
          storage.should_receive(:save).at_least(:twice).and_yield(job)
          subject.should_receive(:schedule).with(job)
          subject.send(:do_job, job)
        end
      end
    end
  end
end