# TODO comment it
module JobReactor
  module MemoryStorage

    @@storage = { }

    class << self
      def storage
        @@storage
      end

      def load(hash, &block)
        hash = storage[hash['id']]
        if hash
          hash_copy = { }
          hash.each { |k, v| hash_copy.merge!(k => v) }
          block.call(hash_copy) if block_given?
        end
      end

      def save(hash, &block)
        unless (hash['id'])
          id = Time.now.to_f.to_s
          hash.merge!('id' => id)
        end
        storage.merge!(hash['id'] => hash)

        block.call(hash) if block_given?
      end

      def destroy(hash)
        storage.delete(hash['id'])
      end

      def jobs_for(name, &block)  #No persistance
        nil
      end
    end

  end
end
