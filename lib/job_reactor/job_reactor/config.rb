# Names are informative
# TODO
module JobReactor
  def self.config
    @@config ||= {}
  end
end

JR = JobReactor

JR.config[:job_directory] = 'reactor_jobs'
JR.config[:max_attempt] = 10
JR.config[:retry_multiplier] = 5
JR.config[:retry_jobs_at_start] = true
JR.config[:merge_job_itself_to_args] = false
JR.config[:log_job_processing] = true
JR.config[:always_use_specified_node] = false #will send job to another node if specified node is not available
JR.config[:remove_done_jobs] = true
JR.config[:remove_cancelled_jobs] = true
JR.config[:remove_failed_jobs] = false

JR.config[:redis_host] = 'localhost'
JR.config[:redis_port] = 6379

#TODO next releases with rails support
#JR.config[:active_record_adapter] = 'mysql2'
#JR.config[:active_record_database] = 'em'
#JR.config[:active_record_user] = ''
#JR.config[:active_record_password] = ''
#JR.config[:active_record_table_name] = 'reactor_jobs'
#JR.config[:use_custom_active_record_connection] = true
