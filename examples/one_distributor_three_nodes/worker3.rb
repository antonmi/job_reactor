$: << "lib"
require 'job_reactor'
JR.config[:job_directory] = 'examples/one_distributor_three_nodes/jobs'

JR.run! do
  JR.start_node({:storage => 'memory_storage', :name => "memory_node", :server => ['192.168.1.3', 2003], :distributors => [['192.168.1.4', 5000]] })
end