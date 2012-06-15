require 'job_reactor/distributor/client'
require 'job_reactor/distributor/server'

module JobReactor
  module Distributor
    extend self

    def host
      @@host
    end

    def port
      @@port
    end

    # Gets nodes
    # You can monitor available nodes connections in you application.
    # For example
    # EM::PeriodicTimer.new(10) { JR::Logger.log nodes}
    #
    def nodes
      @@nodes ||= []
    end

    # Contains connections pool - all node connections
    #
    def connections
      @@connections ||= []
    end

    def server
      @@connect_to || "#{@@host}:#{@@port}"
    end

    #Starts distributor on given hast and port
    #
    def start(host, port, opts = {})
      @@connect_to = opts[:connect_to] && opts[:connect_to].join(':')
      @@host = host
      @@port = port
      JR::Logger.log "Distributor listens #{host}:#{port}"
      EM.start_server(host, port, JobReactor::Distributor::Server)
    end

    # Tries to find available node connection
    # If it is distributor will send marshalled data
    # If get_connection returns nil distributor will try again after 1 second
    #
    def send_data_to_node(hash)
      connection = get_connection(hash)
      if connection
        data = Marshal.dump(hash)
        connection.send_data(data)
        connection.lock
      else
        EM.next_tick do
          send_data_to_node(hash)
        end
      end
    end

    private

    # Looks for available connection.
    # If job hash specified node, tries check if the node is available.
    # If not, returns nil or tries to find any other free node if :always_use_specified_node == true
    # If job hasn't any specified node, methods return any available connection or nil (and will be launched again in one second)
    #
    def get_connection(hash)
      if hash['node']
        node_connection = connections.select{ |con| con.name == hash['node'] && con.name != hash['not_node']}.first
        if node_connection && node_connection.available?
          node_connection
        else
          JR.config[:always_use_specified_node] ?  nil : connections.select{ |con| con.available? && con.name != hash['not_node'] }.first
        end
      else
        connections.select{ |con| con.available? && con.name != hash['not_node'] }.first
      end
    end

  end
end
