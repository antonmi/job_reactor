module JobReactor
  class Node
    class Client < EM::Connection

      def initialize(node, distributor)
        @node = node
        @distributor = distributor
      end

      def post_init
        JR::Logger.log("Searching for distributor #{@distributor.join(' ')} ...")
      end

      # Sends node credentials to distributor.
      #
      def connection_completed
        JR::Logger.log('Begin distributor handshake')
        data = {node_info: @node.config}
        data = Marshal.dump(data)
        JR::Logger.log(data)
        send_data(data)
      end

      # Tries to connect.
      #
      def unbind
        EM::Timer.new(1) do
          @node.connect_to(@distributor)
        end
      end

    end

  end
end