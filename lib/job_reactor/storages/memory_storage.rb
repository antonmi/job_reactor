# TODO comment it
module JobReactor
  module MemoryStorage


    class << self
      def storage
        @storage ||= {}
      end

      def load(hash)
        hash = storage[hash['id']]
        if hash
          hash_copy = {}
          hash.each { |k, v| hash_copy.merge!(k => v) }
          yield hash_copy if block_given?
        end
      end

      def save(hash)
        unless (hash['id'])
          id = Time.now.to_f.to_s
          hash.merge!('id' => id)
        end
        storage.merge!(hash['id'] => hash)

        yield hash if block_given?
      end

      def destroy(hash)
        storage.delete(hash['id'])
      end

      def jobs_for(name, &block)  #No persistence
        nil
      end
    end

  end
end
