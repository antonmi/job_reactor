include JobReactor

puts "="*100

success = 0
job 'success_job' do |args|
  puts 'success'
  puts success+=1
  (1..1000_000).to_a.shuffle!.sort!
  puts args[:job_itself]
  sd
end

error = 0
job 'error_job' do |args|
  puts 'error'
  puts error+=1
  #(1..10_000).to_a.shuffle!.sort!
  bang!
end
