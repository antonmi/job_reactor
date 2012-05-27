$: << "lib"
require 'job_reactor'

JR.config[:job_directory] = 'examples/one_distributor_three_nodes/jobs'

JR.run do
  JR.start_distributor('localhost', 5000)
end

suc = 0
err = 0

success = Proc.new do |args|
  puts "success: #{suc += 1}"
end

error = Proc.new do |args|
  puts "error: #{err += 1}"
end

sleep(1) until(JR.ready?)
sleep(1)
i=0
30000.times do
  JR.enqueue('success_job', {arg1: 1, arg2: 2}, {}, success, error)
  #JR.enqueue('error_job', {arg1: 1, arg2: 2}, {}, success, error )
  puts i+=1
  sleep(0.0005)
end

sleep(1) until err == 1000

