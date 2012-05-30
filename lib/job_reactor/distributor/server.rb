# TODO comment it
module JobReactor
  module Distributor
    class Server < EM::Connection

      def post_init
        JR::Logger.log 'Begin node handshake'
      end

      def receive_data(data)
        data = Marshal.load(data)
        if data[:node_info]
          node_info = data[:node_info]
          JR::Logger.log "Receive data from node: #{data[:node_info]}"
          JobReactor::Distributor.nodes << node_info
          connection = EM.connect(*node_info[:server], Client, node_info[:name])
          JobReactor::Distributor.connections << connection
        elsif data[:success]
          JR.run_succ_feedback(data[:success])
          send_data('ok')
        elsif data[:error]
          JR.run_err_feedback(data[:error])
          send_data('ok')
        end

        data
      end

    end
  end
end