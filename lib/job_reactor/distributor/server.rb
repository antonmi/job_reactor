# TODO comment it
module JobReactor
  module Distributor
    class Server < EM::Connection

      def post_init
        JR::Logger.log 'Begin node handshake'
      end

      def receive_data(data)

        data = Marshal.load(data)
        node_info = data[:node_info]
        if data[:node_info]
          JR::Logger.log "Receive data from node: #{data[:node_info]}"
          JobReactor::Distributor.nodes << node_info
          connection = EM.connect(*node_info[:server], Client, node_info[:name])
          JobReactor::Distributor.connections << connection
        elsif data[:success]
          JR.run_callback(data[:success])
        elsif data[:error]
          JR.run_errback(data[:error])
        end

        data
      end

    end
  end
end