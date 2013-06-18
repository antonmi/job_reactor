# TODO comment it
module JobReactor
  module Distributor
    class Client < EM::Connection
      def initialize(name)
        @name = name
      end

      def name
        @name
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

      def unbind
        JR::JobLogger.log "#{@name} disconnected"
        close_connection
        JobReactor::Distributor.connections.delete(self)
      end
    end
  end
end