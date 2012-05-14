# TODO comment it
require 'active_record'
module JobReactor
  class ActiveRecordStorage < ::ActiveRecord::Base
    establish_connection :adapter => 'mysql2', :database => 'em', :user => 'root', :password => '123456'

    serialize :args, Hash

    ATTRS = %w(name args last_error run_at failed_at attempt period make_after node status)
    attr_accessible *ATTRS

    self.table_name = 'reactor_jobs'
    class << self

      def load(hash, &block)
        if record = self.find_by_id(hash['id'])
          hash = record.attributes
          hash.merge!('storage' => ActiveRecordStorage)
          hash
          block.call(hash) if block_given?
        end
      end

      def save(hash, &block)
        if hash['id']
          record = self.find_by_id(hash['id'])
          keys   = hash.keys
          (keys - ATTRS).each { |key| hash.delete(key) }
          record.update_attributes(hash)
        else
          record = self.create(hash)
        end
        hash.merge!('id' => record.id)
        hash.merge!('storage' => ActiveRecordStorage)
        block.call(hash) if block_given?
      end

      def destroy(hash)
        self.find_by_id(hash['id']).destroy
      end

      def jobs_for(name, &block)
        self.where('attempt < ?', JobReactor.config[:max_attempt])
        .where('status != ?', 'complete')
        .where('status != ?', 'cancelled')
        .where(node: name).map{ |record| record.attributes }.each do |job|
          block.call(job)
        end
      end

    end

  end

end