require 'spec_helper'
require 'job_reactor'

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

  describe '.connect_to' do
    context 'with existing connection' do
      before do
        fake_connection = double('fake_connection')
        fake_connection.should_receive(:reconnect)
        subject.instance_variable_set(:@connections, {connect1: fake_connection})
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
end