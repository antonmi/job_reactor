# The core.
# Gives API to parse jobs, send them to node using distributor, and make them for node.

require 'job_reactor/job_reactor/config'
require 'job_reactor/job_reactor/job_parser'
require 'job_reactor/job_reactor/exceptions'
require 'job_reactor/job_reactor/storages'

module JobReactor

  # Yes, we monkeypatched Ruby core class.
  # Now all hashes hash EM::Deferrable callbacks and errbacks.
  # It is just for simplicity.
  # It's cool use 'job = {}' instead 'job = JobHash.new.
  # We are ready to discuss it and change.
  #
  Hash.send(:include, EM::Deferrable)

  class << self

    # Accessors to jobs.
    #
    def jobs
      @@jobs ||= { }
    end

    # Ready flag.
    # @@ready is true when block is called inside EM reactor.
    #
    def ready!
      @@ready = true
    end

    def ready?
      (@@ready ||= false) && EM.reactor_running?
    end

    # Requires storage
    # Creates and start node.
    #
    def start_node(opts)
      require_storage!(opts)
      node = Node.new(opts)
      node.start
    end

    def start_distributor(host, port)
      JR::Distributor.start(host, port)
    end

    def succ_feedbacks
      @@callbacks ||= { }
    end

    def err_feedbacks
      @@errbacks ||= { }
    end

    # Here is the only method user can call inside the application (excepts start-up methods, of course).
    # You have to specify job_name and optionally its args and opts.
    # The method set initial arguments and send job to distributor which will send it to node.
    # Options are :after and :period (for deferred and periodic jobs), and :node to specify the preferred node to launch job.
    # Use :always_use_specified_node option to be sure that job will launched in the specified node.
    # Job itself is a hash with the following keys:
    # name, args, make_after, last_error, run_at, failed_at, attempt, period, node, not_node, status.
    #
    def enqueue(name, args = { }, opts = { }, success_proc = nil, error_proc = nil)
      raise NoSuchJob unless JR.jobs[name]
      hash = { 'name' => name, 'args' => args, 'attempt' => 0, 'status' => 'new' }

      hash.merge!('period' => opts[:period]) if opts[:period]
      opts[:after] = (opts[:run_at] - Time.now) if opts[:run_at]
      hash.merge!('make_after' => (opts[:after] || 0))

      hash.merge!('node' => opts[:node]) if opts[:node]
      hash.merge!('not_node' => opts[:not_node]) if opts[:not_node]

      hash.merge!('distributor' => "#{JR::Distributor.host}:#{JR::Distributor.port}")

      add_succ_feedbacks!(hash, success_proc) if success_proc
      add_err_feedbacks!(hash, error_proc) if error_proc

      JR::Distributor.send_data_to_node(hash)
    end


    # This method is used by node (Node#schedule).
    # It makes job from hash by calling callback and errback methods.
    #
    # The strategy is the following:
    # First and last callback (add_start_callback) are informational.
    # Second is the proc specified in JR.job method.
    # Third and ... are the procs specified in job_callbacks.
    #
    # Then errbacks are attached.
    # They are called when error occurs in callbacks.
    # The last errback raise exception again to return job back to node workflow.
    # See Node#do_job method to better understand how this works.
    #
    def make(hash) #new job is a Hash
      raise NoSuchJob unless jr_job = JR.jobs[hash['name']] #TODO Fixed question. How he should fail???

      job = hash
      add_start_callback(job) if JR.config[:log_job_processing]
      job.callback(&jr_job[:job])

      jr_job[:callbacks].each do |callback|
        job.callback(&callback[1])
      end if jr_job[:callbacks]

      add_last_callback(job) if JR.config[:log_job_processing]

      add_start_errback(job) if JR.config[:log_job_processing]

      jr_job[:errbacks].each do |errback|
        job.errback(&errback[1])
      end if jr_job[:errbacks]

      add_complete_errback(job) if JR.config[:log_job_processing]

      job
    end

    # Runs success callbacks with job args
    #
    def run_succ_feedback(data)
      proc = data[:do_not_delete] ? succ_feedbacks[data[:callback_id]] : succ_feedbacks.delete(data[:callback_id])
      proc.call(data[:args]) if proc
    end

    # Runs error callbacks with job args
    # Exception class is in args[:error]
    #
    def run_err_feedback(data)
      proc = err_feedbacks.delete(data[:errback_id])
      proc.call(data[:args]) if proc
    end

    private

    # Requires storage and change opts[:storage] to the constant
    #
    def require_storage!(opts)
      require "job_reactor/storages/#{opts[:storage]}"
      opts[:storage] = STORAGES[opts[:storage]]
    end

    # Loads all *.rb files in the :job_directory folder
    # See job_reactor/job_parser to understand how job hash is built
    #
    def parse_jobs
      JR.config[:job_directory] += '/**/*.rb'
      Dir[JR.config[:job_directory]].each {|file| load file }
    end

    # Adds success callback which will launch when node reports success
    #
    def add_succ_feedbacks!(hash, callback)
      distributor = "#{JR::Distributor.host}:#{JR::Distributor.port}"
      feedback_id = "#{distributor}_#{Time.now.utc.to_f}"
      succ_feedbacks.merge!(feedback_id => callback)
      hash.merge!('on_success' => feedback_id)
    end

    # Adds error callback which will launch when node reports error
    #
    def add_err_feedbacks!(hash, errback)
      distributor = "#{JR::Distributor.host}:#{JR::Distributor.port}"
      feedback_id = "#{distributor}_#{Time.now.utc.to_f}"
      err_feedbacks.merge!(feedback_id => errback)
      hash.merge!('on_error' => feedback_id)
    end

    # Logs the beginning.
    #
    def add_start_callback(job)
      job.callback do
        JR::Logger.log_event(:start, job)
      end
    end

    # Logs the completing
    #
    def add_last_callback(job)
      job.callback do
        JR::Logger.log_event(:complete, job)
      end
    end

    # Logs the beginning or error cycle.
    #
    def add_start_errback(job)
      job.errback do
        JR::Logger.log_event(:error, job)
      end
    end

    # Logs the end of error cycle
    #
    def add_complete_errback(job)
      job.errback do
        JR::Logger.log_event(:error_complete, job)
      end
    end

  end
end