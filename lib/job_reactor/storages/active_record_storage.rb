# TODO comment it
require 'active_record'

module JobReactor
  class ActiveRecordStorage < ::ActiveRecord::Base

    establish_connection(
        :adapter => JR.config[:active_record_adapter],
        :database => JR.config[:active_record_database],
        :user => JR.config[:active_record_user],
        :password => JR.config[:active_record_password]
    ) if JR.config[:use_custom_active_record_connection]

    serialize :args, Hash

    ATTRS = %w(name args last_error run_at failed_at attempt period make_after node status distributor on_success on_error)
    attr_accessible *ATTRS

    self.table_name = JR.config[:active_record_table_name]

    class << self

      def load(hash, &block)
        if record = self.find_by_id(hash['id'])
          hash = record.attributes
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