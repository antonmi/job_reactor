$: << "lib"
require 'job_reactor'

require "pry"

JR.run do
  JR.config[:job_directory] = 'examples/one_distributor_one_node/jobs'
  JR.start_distributor('192.168.1.3', 5001)
end


loop do
sleep(10)
JR.enqueue('test_job', {arg1: 1, arg2: 2})
end

