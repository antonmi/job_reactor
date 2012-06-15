module JobReactor
  class Node
    class Client < EM::Connection

      def initialize(node, distributor)
        @node = node
        @distributor = distributor
      end

      def post_init
        JR::Logger.log("Searching for distributor: #{@distributor.join(' ')} ...")
      end

      def lock
        @lock = true
      end

      def unlock
        @lock = false
      end

      def locked?
        @lock
      end

      def available?
        !locked?
      end

      def receive_data(data)
        self.unlock if data == 'ok'
      end

      # Sends node credentials to distributor.
      #
      def connection_completed
        JR::Logger.log('Begin distributor handshake')
        data = {node_info: {name: @node.config[:name], server: @node.server} }
        data = Marshal.dump(data)
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