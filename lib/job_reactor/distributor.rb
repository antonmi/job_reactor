require 'distributor/client'
require 'distributor/server'

module JobReactor
  module Distributor
    extend self

    def nodes
      @@nodes ||= []
    end

    # Contains connections pool
    def connections
      @@connections ||= []
    end

    #Starts distributor on given hast and port

    def start(host, port)
      EM.start_server(host, port, JobReactor::Distributor::Server, [host, port])
      JR::Logger.log "Distributor listens #{host}:#{port}"
      EM.add_periodic_timer(5) do
        JR::Logger.log('Available nodes: ' << JR::Distributor.connections.map(&:name).join(' '))
      end
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
          puts 'locked'
          send_data_to_node(hash)
        end
      end
    end

    private

    # Looks for available connection.
    # If job hash specified node, tries check if the node is available.
    # If not, returns nil or tries to find any other free node if :always_use_specified_node == true
    # If job hasn't any specified node, methods return any available connection or nil (and will be launched again in one second)

    def get_connection(hash)
      check_node_pool
      if hash['node']
        node_connection = connections.select{ |con| con.name == hash['node'] }.first
        JR::Logger.log("WARNING: Node #{hash['node']} is not available") unless node_connection
        if node_connection.try(:available?)
          node_connection
        else
          JR.config[:always_use_specified_node] ?  nil : connections.select{ |con| con.available? }.first
        end
      else
        connections.select{ |con| con.available? }.first
      end
    end

    # Checks node poll. If it is empty will fail after :when_node_pull_is_empty_will_raise_exception_after seconds
    # The distributor will fail when number of timers raise to EM.get_max_timers which if default 100000 for the majority system
    # To exit earlier may be useful for error detection
    #
    def check_node_pool
      if connections.size == 0
        JR::Logger.log 'Warning: Node pool is empty'
        EM::Timer.new(JR.config[:when_node_pull_is_empty_will_raise_exception_after]) do
          if connections.size == 0
            raise JobReactor::NodePoolIsEmpty
          end
        end
      end
    end

  end
end
