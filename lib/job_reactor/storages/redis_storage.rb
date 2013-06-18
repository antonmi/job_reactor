# TODO comment it
require 'em-hiredis'

module JobReactor
  module RedisStorage
    @storage =  EM::Hiredis.connect(JobReactor.config[:redis_url])
    ATTRS = %w(id name args last_error run_at failed_at attempt period make_after status distributor on_success on_error defer)

    class << self

      def storage
        @storage
      end

      def load(hash)
        key = "#{hash['node']}_#{hash['id']}"
        hash_copy = {'node' => hash['node']} #need new object, because old one has been 'failed'

        storage.hmget(key, *ATTRS) do |record|
          unless record.compact.empty?
            ATTRS.each_with_index do |attr, i|
              hash_copy[attr] = record[i]
            end
            ['attempt', 'period', 'make_after'].each do |attr|
              hash_copy[attr] = hash_copy[attr].to_i
            end
            hash_copy['args'] = Marshal.load(hash_copy['args'])

            yield hash_copy if block_given?
          end
        end
      end


      def save(hash)
        hash.merge!('id' => Time.now.to_f.to_s) unless hash['id']
        key = "#{hash['node']}_#{hash['id']}"
        args, hash['args'] = hash['args'], Marshal.dump(hash['args'])

        storage.hmset(key, *ATTRS.map{|attr| [attr, hash[attr]]}.flatten) do
          hash['args'] = args

          yield hash if block_given?
        end
      end

      def destroy(hash)
        storage.del("#{hash['node']}_#{hash['id']}")
      end

      def destroy_all_jobs_for(name)
        pattern = "*#{name}_*"
        storage.del(*storage.keys(pattern))
      end

      def jobs_for(name)
        pattern = "*#{name}_*"
        storage.keys(pattern) do |keys|
          keys.each do |key|
            hash = {}
            storage.hget(key, 'id') do |id|
              hash['id'] = id
              hash['node'] = name
              self.load(hash) do |hash|
                if hash['status'] != 'complete' && hash['status'] != 'cancelled' && hash['status'] != 'failed'
                else
                  yield hash if block_given?
                end
              end
            end
          end
        end
      end

    end

  end

end