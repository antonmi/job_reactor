require 'job_reactor'

include JobReactor

puts "="*100

i=0
job 'test_job' do |args|
  puts 'job'
  puts i+=1
  #(1..10_000_000).to_a.shuffle!.sort!
end
