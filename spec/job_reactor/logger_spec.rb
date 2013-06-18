require 'spec_helper'

describe JR::JobLogger do
  subject { JR::JobLogger }
  let(:stdout) { StringIO.new }
  before { subject.stdout = stdout }

  describe '.log_event' do
    let(:event) { mock(:to_s => "MyEvent") }
    let(:job) { { 'name' => 'my_job_name' } }
    before { subject.log_event(event, job) }
    it('should log event') { stdout.string.should include('MyEvent') }
    it('should log job') { stdout.string.should include('my_job_name') }
  end

  describe '.log' do
    before { subject.log('Some custom message') }
    it('should add message to output') { stdout.string.should include('Some custom message') }
  end

  describe '.stdout=' do
    let(:stream){mock('stream')}
    before do
      @old_stdout = JR::JobLogger.stdout
      JR::JobLogger.stdout = stream
    end
    after { JR::JobLogger.stdout = @old_stdout }
    it("should set @stdout") { JR::JobLogger.instance_variable_get(:@stdout).should == stream }
    context ":rails_logger" do
      let(:logger) { mock('rails_logger') }
      before do
        logger.should_receive(:info).any_number_of_times
        Rails = mock('rails', :logger => logger )
      end
    end

  end
end