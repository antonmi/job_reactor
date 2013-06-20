require 'redis'
module JobReactor
  module RedisMonitor

    ATTRS = %w(id name args last_error run_at failed_at attempt period make_after status distributor on_success on_error defer)

    extend self

    def storage
      @storage ||= Redis.new(host: JR.config[:redis_host], port: JR.config[:redis_port])
    end

    # Returns all job for given node.
    #
    def jobs_for(name, to_be_retried = false)
      pattern = "*#{name}_*"
      keys = storage.keys(pattern)
      result = {}
      keys.each do |key|
        hash = self.load(key)
        if to_be_retried
          result.merge!(key => hash)  if hash['status'] != 'complete' && hash['status'] != 'cancelled' && hash['status'] != 'failed'
        else
          result.merge!(key => hash)
        end
      end
      result
    end

    # Load job from storage.
    #
    def load(key)
      hash = {}
      record = storage.hmget(key, *ATTRS)
      ATTRS.each_with_index do |attr, i|
        hash[attr] = record[i]
      end
      ['attempt', 'period', 'make_after'].each do |attr|
        hash[attr] = hash[attr].to_i
      end
      hash['args'] = Marshal.load(hash['args'])

      hash
    end

    def destroy(key)
      storage.del(key)
    end

    # Destroys all job for given node.
    #
    def destroy_all_jobs_for(name)
      pattern = "*#{name}_*"
      storage.del(*storage.keys(pattern)) unless storage.keys(pattern).empty?
    end

  end
end