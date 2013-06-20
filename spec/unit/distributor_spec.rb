require 'spec_helper'

describe JobReactor::Distributor do

  before :all do
    EM.stop if EM.reactor_running?
    wait_until(5) { !EM.reactor_running? }
  end

  it 'should try start server' do
    EM.should_receive(:start_server).with('host', 'port', JobReactor::Distributor::Server)
    JobReactor::Distributor.start('host', 'port')
  end

  it 'should return server address' do
    EM.should_receive(:start_server).with('host', 'port', JobReactor::Distributor::Server)
    JobReactor::Distributor.start('host', 'port')
    JobReactor::Distributor.server.should == 'host:port'
  end

  it 'should return the right server address' do
    EM.should_receive(:start_server).with('host', 'port', JobReactor::Distributor::Server)
    JobReactor::Distributor.start('host', 'port', :connect_to => ['new_host', 'new_port'])
    JobReactor::Distributor.server.should == 'new_host:new_port'
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