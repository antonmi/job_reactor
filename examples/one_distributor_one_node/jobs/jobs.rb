require 'job_reactor'

include JobReactor

puts "="*100


job 'test_job' do |args|
  puts 'job'
  puts args
  (1..10_000_000).to_a.shuffle!.sort!
end
