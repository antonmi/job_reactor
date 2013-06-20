# Names are informative
# TODO
module JobReactor
  def self.config
    @config ||= {}
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

JR.config[:hiredis_url] = "redis://localhost:6379"
JR.config[:redis_host] = 'localhost'
JR.config[:redis_port] = 6379

JR.config[:logger_method] = :puts
