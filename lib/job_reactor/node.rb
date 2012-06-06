require 'job_reactor/node/server'
require 'job_reactor/node/client'
module JobReactor
  class Node

    def initialize(opts)
      @config = { storage: opts[:storage], name: opts[:name], server: opts[:server], distributors: opts[:distributors]}
    end

    def config
      @config
    end

    # Config accessors.
    #
    [:storage, :name, :server, :distributors].each do |method|
      define_method(method) do
        config[method]
      end
    end

    # Store distributor connection instances.
    #
    def connections
      @connections ||= {}
    end

    # Retrying jobs if any,
    # starts server and tries to connect to distributors.
    #
    def start
      retry_jobs if JR.config[:retry_jobs_at_start]
      EM.start_server(*self.config[:server], Server, self, self.storage)
      self.config[:distributors].each do |distributor|
        connect_to(distributor)
      end
    end

    # Connects to distributor.
    # This method is public, because it is called by client when connection interrupt.
    #
    def connect_to(distributor)
      if connections[distributor]
        JR::Logger.log "Searching for distributor #{distributor.join(' ')}"
        connections[distributor].reconnect(*distributor)
      else
        connections.merge!(distributor => EM.connect(*distributor, Client, self, distributor))
      end
    end

    # The method is called by node server.
    # It makes a job and run do_job.
    #
    def schedule(hash)
      EM::Timer.new(hash['make_after']) do  #Of course, we can start job immediately (unless it is 'after' job), but we let EM take care about it. Maybe there is another job is ready to start
        self.storage.load(hash) do |hash|
          do_job(JR.make(hash))
        end
      end
    end

    private

    # Calls succeed on deferrable object.
    # When job (or it's callbacks) fails, errbacks are launched.
    # If errbacks fails job will be relaunched.
    #
    # You can see custom exception 'CancelJob''.
    # You can use it to change normal execution.
    #
    def do_job(job)
      job['run_at'] = Time.now
      job['status'] = 'in progress'
      job['attempt'] += 1
      storage.save(job) do |job|
        begin
          args = job['args'].merge(JR.config[:merge_job_itself_to_args] ? {:job_itself => job.dup} : {})
          job.succeed(args)
          job['args'] = args
          job_completed(job)
        rescue CancelJob
          cancel_job(job)
        rescue Exception => e
          rescue_job(e, job)
        end
      end
    end

    # Reports success to distributor if should do it.
    # If job is 'periodic' job schedule it again.
    # Sets status completed or removes job from storage.
    #
    def job_completed(job)
      report_success(job) if job['on_success']
      if job['period'] && job['period'].to_i > 0
        job['status'] = 'queued'
        job['make_after'] = job['period']
        job['args'].delete(:job_itself)
        storage.save(job) { |job| schedule(job) }
      else
        if JR.config[:remove_done_jobs]
          storage.destroy(job)
        else
          job['status'] = 'complete'
          storage.save(job)
        end
      end
    end

    #Lanches job errbacks
    #
    def rescue_job(e, job)
      begin
        job['failed_at']  = Time.now #Save error info
        job['last_error'] = e
        job['status']     = 'error'
        self.storage.save(job) do |job|
          begin
            args = job['args'].merge!(:error => e).merge(JR.config[:merge_job_itself_to_args] ? { :job_itself => job.dup } : { })
            job.fail(args) #Fire errbacks. You can access error in you errbacks (args[:error])
            job['args'] = args
            complete_rescue(job)
          rescue JobReactor::CancelJob
            cancel_job(job, true) #If it was cancelled we destroy it or set status 'cancelled'
          rescue Exception => e  #Recsue Exceptions in errbacks
            job['args'].merge!(:errback_error => e) #So in args you now have :error and :errback_error
            complete_rescue(job)
          end
        end
      end
    end

    #Tryes again or report error
    #
    def complete_rescue(job)
      if job['attempt'].to_i < JobReactor.config[:max_attempt]
        try_again(job)
      else
        job['status'] = 'failed'
        report_error(job) if job['on_error']
        if JR.config[:remove_failed_jobs]
          storage.destroy(job)
        else
          storage.save(job)
        end
      end
    end

    # Cancels job. Remove or set 'cancelled status'
    #
    def cancel_job(job, error = false)
      report_success(job) if !error && job['on_success']
      report_error(job) if error && job['on_error']
      if JR.config[:remove_cancelled_jobs]
        storage.destroy(job)
      else
        job['status'] = 'cancelled'
        storage.save(job)
      end
    end

    # try_again has special condition for periodic jobs.
    # They will be rescheduled after period time.
    #
    def try_again(job)
      if job['period'] && job['period'] > 0
        job['make_after'] = job['period']
      else
        job['make_after'] = job['attempt'] * JobReactor.config[:retry_multiplier]
      end
      job['args'].delete(:job_itself)
      self.storage.save(job) do |job|
        self.schedule(job)
      end
    end

    # Retries jobs.
    # Runs only once when node starts.
    #
    def retry_jobs
      storage.jobs_for(name) do |job_to_retry|
        job_to_retry['args'].merge!(:retrying => true)
        try_again(job_to_retry) if job_to_retry
      end
    end

    # Reports success to node, sends jobs args
    #
    def report_success(job)
      host, port = job['distributor'].split(':')
      port = port.to_i
      distributor = self.connections[[host, port]]
      data = {:success => { callback_id: job['on_success'], args: job['args']}}
      data[:success].merge!(do_not_delete: true) if job['period'] && job['period'].to_i > 0
      data = Marshal.dump(data)
      send_data_to_distributor(distributor, data)
    end

    # Reports error to node, sends jobs args.
    # Exception class is merged to args.
    #
    def report_error(job)
      host, port = job['distributor'].split(':')
      port = port.to_i
      distributor = self.connections[[host, port]]
      data = {:error => { errback_id: job['on_error'], args: job['args']}}
      data = Marshal.dump(data)
      send_data_to_distributor(distributor, data)
    end

    # Sends data to distributor
    #
    def send_data_to_distributor(distributor, data)
      if distributor.locked?
        EM.next_tick do
          send_data_to_distributor(distributor, data)
        end
      else
        distributor.send_data(data)
        distributor.lock
      end
    end

  end
end
