require 'spec_helper'
require 'job_reactor'

describe JobReactor do
  context "initializaiton" do
    describe '.run' do
      before do
        Thread.should_receive(:new).and_yield
        EM.should_receive(:run).and_yield
      end
      it "should run EM in different thead" do
        JobReactor.run
      end
    end
    describe '.run!' do
      before { Thread.should_not_receive(:new!) }
      context "EM.reactor_running?" do
        before do
          EM.stub(:reactor_running? => true)
          EM.should_not_receive(:run)
        end
        it("should not start EM") { JobReactor.run! }
      end
    context "not EM.reactor_running?" do
        before do
          EM.stub(:reactor_running? => false)
          EM.should_receive(:run).and_yield
        end
        it("should start EM") { JobReactor.run! }
      end
    end
    describe '.wait_em_and_run' do
      before do
        Thread.should_receive(:new).and_yield
        EM.should_receive(:schedule).and_yield
      end
      it "should call sleep till EM isn't running" do
        EM.stub(:reactor_running?).and_return(false, true)
        JobReactor.should_receive(:sleep)
        JobReactor.wait_em_and_run
      end

    end
  end
end
