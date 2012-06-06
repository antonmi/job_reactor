require 'spec_helper'

describe JobReactor::Distributor do

  before :all do
    EM.stop if EM.reactor_running?
    sleep(5)
  end

  it 'should try start server' do
    EM.should_receive(:start_server).with('host', 'port', JobReactor::Distributor::Server)
    JobReactor::Distributor.start('host', 'port')
  end

  context 'server' do
    it 'should start server' do
      JobReactor::Distributor::Server.any_instance.should_receive(:post_init)
      EM.run do
        JobReactor::Distributor.start('localhost', '5000')
        EM.connect('localhost', '5000')
        EM.stop
      end
    end
  end

end