require 'spec_helper'
require 'job_reactor'

def options
  { storage: 'storage', name: 'name', server: 'server', distributors: ['distributors'] }
end

describe JR::Node do
  subject { JR::Node.new(options) }
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

  describe '.start!' do
    before do
      subject.stub(:retry_jobs)
      EM.stub(:start_server)
      subject.stub(:connect_to)
    end
    it "should retry_jobs" do
      subject.should_receive(:retry_jobs)
      subject.start!
    end
    it "should start EM server" do
      EM.should_receive(:start_server)
      subject.start!
    end
    it "should try to connect to each distributor given" do
      subject.should_receive(:connect_to).exactly(options[:distributors].size).times
      subject.start!
    end
  end

end