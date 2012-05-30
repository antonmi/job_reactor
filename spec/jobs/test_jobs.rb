puts 'Loading jobs'
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
ARRAY = []
#ARRAY.clear

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


