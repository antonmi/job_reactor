$: << "lib"
require 'job_reactor'

JR.config[:job_directory] = 'examples/one_distributor_three_nodes/jobs'

JR.run do
  JR.start_distributor('localhost', 5000)
end

i=0
loop do
  JR.enqueue('test_job', {arg1: 1, arg2: 2})
  puts i+=1
  sleep(0.0005)
end

