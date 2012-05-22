require 'job_reactor'

include JobReactor

puts "="*100


job 'test_job' do |args|
  puts 'job'
  puts args.merge!(:aaa=>'wewewewewe')
  (1..1_000_000).to_a.shuffle!.sort!
end


job_callback 'test_job', 'first_callback' do |args|
  puts 'callback'
  puts args[:aaa]
  iui
end

job_callback 'test_job', 'second_callback' do |args|
  puts 'another_callback'
  puts 'Test job is complete'
end

job_errback 'test_job', 'first_errback' do |args|
  puts args[:error]

  puts 'errback'
end

job_errback 'test_job', 'second_errback' do |args|
  puts 'another_errback'
end



#after job
job 'after' do |args|
  puts 'I am after job'
  puts args
  sleep(1)
end

#start_at job
job 'start_at' do |args|
  puts 'I am start_at job'
end

#peridic job
job 'periodic' do |args|
  puts '()'*100 if args[:retrying]
  raise JobReactor::CancelJob if args[:retrying]
  puts 'I am periodic job'
  puts args[:job_itself]
  puts args[:arg1]
  puts args.class
  dsfsd
end

job_errback 'periodic' do |args|
  puts 'periodic errback'
  puts args[:error]
end
