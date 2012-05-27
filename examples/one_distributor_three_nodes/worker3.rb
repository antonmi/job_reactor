$: << "lib"
require 'job_reactor'
JR.config[:job_directory] = 'examples/one_distributor_three_nodes/jobs'

JR.run! do
  JR.start_node({:storage => 'memory_storage', :name => "memory_node", :server => ['localhost', 2003], :distributors => [['localhost', 5000]] })
end