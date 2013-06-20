require 'spec_helper'

module JobReactor
  module MemoryStorage
    def self.flush_storage
      @storage = {}
    end
  end

end

describe 'simple job', :slow => true do
  before do
    EM.stop if EM.reactor_running?
    wait_until { !EM.reactor_running? }
    ARRAY = [] unless defined? ARRAY
    JR.config[:job_directory] = File.expand_path('../../jobs', __FILE__)
    JR.config[:retry_multiplier] = 0
    JR.config[:max_attempt] = 5
    JR.run do
      JR.start_distributor('localhost', 5009)
      JR.start_node({ storage: 'memory_storage', name: 'memory_node', server: ['localhost', 7009], distributors: [['localhost', 5009]] })
    end
    wait_until { EM.reactor_running? }
    JR::MemoryStorage.flush_storage
    ARRAY.clear
  end

  require 'integration/shared_examples_for_simple_jobs'


  it_behaves_like 'Simple Jobs'
end
