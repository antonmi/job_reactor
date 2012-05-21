require 'spec_helper'
require 'job_reactor'

describe JobReactor::Logger do
  subject { JobReactor::Logger }
  let(:stdout) { StringIO.new }
  before { subject.stdout = stdout }

  describe '.log_event' do
    let(:event) { mock(:to_s => "MyEvent") }
    let(:job) { {'name' => 'my_job_name'} }
    before { subject.log_event(event, job) }
    it('should log event') { stdout.string.should include('MyEvent') }
    it('should log job') { stdout.string.should include('my_job_name') }
  end

  describe '.log' do
    before { subject.log('Some custom message') }
    it('should add message to output') { stdout.string.should include('Some custom message') }
  end

  describe '.dev_log' do
    context 'in JR development environment' do
      before do
        JR::Logger.stub(:development? => true)
        subject.dev_log('Some dev message')
      end
      it('should add message to output') { stdout.string.should include('Some dev message') }
    end

    context 'in JR production environment' do
      before do
        JR::Logger.stub(:development? => false)
        subject.dev_log('Some dev message')
      end
      it('should add message to output') { stdout.string.should_not include('Some dev message') }
    end
  end

  describe '.development?' do
    it('by default should return false') { subject.development?.should be_false }
    context 'for development environment' do
      before { JR::Logger.development = true }
      it('should return true') { subject.development?.should be_true }
    end
  end
end