module JobReactor
  class Node
    class Server < EM::Connection

      #Need to know the storage to call save method on it
      #Need to now node name to send it to the distributor
      #
      def initialize(node, storage)
        @storage = storage
        @node = node
      end

      #Ok, node is connected and ready to work
      #
      def post_init
        JR::Logger.log("#{@node.name} ready to work")
      end

      # It is the place where job life cycle begins.
      # This method:
      # -receives data from distributor;
      # -saves them in storage;
      # -returns 'ok' to unlock node connection;
      # -and schedules job;
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