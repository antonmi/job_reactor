require 'job_reactor'

include JobReactor

puts "="*100


job 'create' do |args|
  puts 'job'
  puts self
  puts args
end

job_callback 'create', 'first_callback' do |args|
  puts 'callback'
  puts args
end

job_callback 'create', 'second_callback' do |args|
  puts 'another_callback'
  (1..1_000_000).to_a.shuffle!.sort!
  puts args[:job_itself]
  puts args
  ewrwer
end

job_errback 'create', 'first_errback' do |args|
  puts 'errback'
  puts args
  puts args[:job]
  puts args[:job_itself]
  #raise JobReactor::CancelJob
  puts args
  puts args[:exception]
end

job_errback 'create', 'second_errback' do |args|
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
  puts 'I am periodic job'
  puts args[:arg1]
  puts args.class
  gdfgdf
end

job_errback 'periodic' do |args|
  puts 'periodic errback'
  puts args[:job_itself]
  puts args[:error]
end
