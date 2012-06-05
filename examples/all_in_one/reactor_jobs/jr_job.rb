include JobReactor

job 'test_job' do |args|
  puts 'job'
  puts args
  args.merge!('result' => 'RESULT')
  (1..100_000).to_a.shuffle!.sort!
end


job_callback 'test_job', 'first_callback' do |args|
  puts 'callback'
  puts args
end

job_callback 'test_job', 'second_callback' do |args|
  puts 'another_callback'
  puts args
end

job_errback 'test_job', 'first_errback' do |args|
  puts 'errback'
  puts args
  args.merge!('err' => 'ERR')
end

job_errback 'test_job', 'second_errback' do |args|
  puts 'another_errback'
  puts args
end
