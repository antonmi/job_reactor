module JobReactor
  class Node
    class Server < EM::Connection
      def initialize(node, storage)
        @storage = storage
        @node = node
      end

      def post_init
        JR::Logger.log("#{@node.name} ready to work")
      end

      # It is the place where job life cycle begins.
      # This method:
      # -receive data from distributor;
      # -save them in storage;
      # -return 'ok' to unlock node;
      # -and schedule job;
      #
      def receive_data(data)
        hash = Marshal.load(data)
        JR::Logger.log("#{@node.name} received job: #{hash}")
        hash.merge!('node' => @node.name)
        @storage.save(hash) do |hash|
          @node.schedule(hash)
        end
        send_data('ok')
      end

    end

  end
end