# TODO comment it
module JobReactor
  module Distributor
    class Server < EM::Connection

      def post_init
        JR::Logger.log 'Begin node handshake'
      end

      def receive_data(data)
        JR::Logger.log 'Receive data from node'
        data = Marshal.load(data)
        node_info = data[:node_info]

        if data[:node_info]
          JobReactor::Distributor.nodes << node_info
          connection = EM.connect(*node_info[:server], Client, node_info[:name])
          JobReactor::Distributor.connections << connection
          send_data('jobs?')
        end

        data
      end

    end
  end
end