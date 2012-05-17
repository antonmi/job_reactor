puts 'Loading jobs'
include JobReactor

job 'test_job' do |args|
  puts 'job'
  puts args
  (1..10_000_000).to_a.shuffle!.sort!
end


job_callback 'test_job', 'first_callback' do |args|
  puts 'callback'
end

job_errback 'test_job', 'first_errback' do |args|
  puts args[:error]
  puts 'errback'
end
