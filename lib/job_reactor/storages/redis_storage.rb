# TODO comment it
require 'em-redis'

module JobReactor
  module RedisStorage
    @@storage = EM::Protocols::Redis.connect(host: JobReactor.config[:redis_host], port: JobReactor.config[:redis_port])
    ATTRS = %w(id name args last_error run_at failed_at attempt period make_after status)

    class << self

      def storage
        @@storage
      end

      def load(hash, &block)
        key = "#{hash['node']}_#{hash['id']}"
        hash_copy = {'node' => hash['node']} #need new object, because old one has been 'failed'

        storage.hmget(key, *ATTRS) do |record|
          ATTRS.each_with_index do |attr, i|
            hash_copy[attr] = record[i]
          end
          ['attempt', 'period', 'make_after'].each do |attr|
            hash_copy[attr] = hash_copy[attr].to_i
          end
          hash_copy['args'] = Marshal.load(hash_copy['args'])
          hash_copy.merge!('storage' => RedisStorage)

          block.call(hash_copy) if block_given?
        end
      end


      def save(hash, &block)
        hash.merge!('id' => Time.now.to_f.to_s) unless hash['id']
        key = "#{hash['node']}_#{hash['id']}"
        args, hash['args'] = hash['args'], Marshal.dump(hash['args'])

        storage.hmset(key, *ATTRS.map{|attr| [attr, hash[attr]]}.flatten) do
          hash.merge!('storage' => RedisStorage)
          storage.expire("#{hash['node']}_#{hash['id']}")
          hash['args'] = args

          block.call(hash) if block_given?
        end
      end

      def destroy(hash)
        storage.del("#{hash['node']}_#{hash['id']}")
      end

      def destroy_all_jobs_for(name)
        pattern = "*#{name}_*"
        storage.del(*storage.keys(pattern))
      end

      def jobs_for(name, &block)
        pattern = "*#{name}_*"
        storage.keys(pattern) do |keys|
          keys.each do |key|
            hash = {}
            storage.hget(key, 'id') do |id|
              hash['id'] = id
              hash['node'] = name
              self.load(hash) do |hash|
                if hash['status'] != 'complete' && hash['status'] != 'cancelled' && hash['attempt'].to_i < JobReactor.config[:max_attempt]
                  block.call(hash)
                end
              end
            end
          end
        end
      end

    end

  end

end