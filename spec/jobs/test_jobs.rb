include JobReactor

#For job_reactor_spec
job 'test_job' do |args|
end

job_callback 'test_job', 'first_callback' do |args|
end

job_errback 'test_job', 'first_errback' do |args|
end
#--------


#For integration/simple_jobs_spec

job 'simple' do |args|
  ARRAY << ['simple', args]
end

job 'simple_fail' do
  ARRAY << 'fail'
  raise Fail
end

job 'simple_after' do
  ARRAY << Time.now
end

job 'simple_run_at' do
  ARRAY << Time.now
end
#-----------

#For integration/jobs_with_feedback_spec
job 'feedback' do |args|
  args.merge!(:result => 'ok')
end

job 'feedback_with_error' do |args|
  feed_back_error #undefined local variable or method `feed_back_error'
end

job 'will_cancel' do |args|
  args[:arg] += 1
  raise CancelJob if args[:arg] > 3
end

job 'will_cancel_in_errback' do |args|
  args[:arg] += 1
  some_error if args[:arg] > 3
end

job_errback 'will_cancel_in_errback' do |args|
  raise CancelJob
end


