# The core.
# Gives API to parse jobs, send them to node using distributor, and make them for node.

require 'job_reactor/job_reactor/config'
require 'job_reactor/job_reactor/job_parser'
require 'job_reactor/job_reactor/exceptions'
require 'job_reactor/job_reactor/storages'
require 'job_reactor/storages/redis_monitor'

module JobReactor

  # Yes, we monkeypatched Ruby core class.
  # Now all hashes has EM::Deferrable callbacks and errbacks.
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

    # Parses jobs.
    # Requires storage.
    # Creates and start node.
    # Options are:
    # :storage - now available: 'memory_storage' and 'redis_storage';
    # :name - uniq node name like 'my_favorite_memory_node';
    # :server - address where node server starts (example: ['123.123.123.123', 1234];
    # :distributors - address or addresses of distributor(s) node will try to connect (example: [['111.111.111.111', 5000], ['localhost', 5001]]);
    # :connect_to - use this option if you have different ip-address to access your machine from outside world. Example (connect_to: ['213.122.132.231', 8000]).
    # If you specify :connect_to option the connected distributor will use this host and port to connect the node.
    # If not, distributor will use host and port from :server option.
    #
    def start_node(opts)
      parse_jobs
      require_storage!(opts)
      node = Node.new(opts)
      node.start
    end

    # Starts distributor server on given host and port.
    # If you have different ip-address to access your machine from outside world use additional option :connect_to.
    # For example:
    # JR.start_distributor('0.0.0.0', 5000, connect_to: ['123,223,234,213', 5000]).
    # So the node will use '123,223,234,213:5000' to send the 'feedbacks' to distributor
    #
    def start_distributor(host, port, opts = {})
      JR::Distributor.start(host, port, opts)
    end

    def succ_feedbacks
      @@succ_feedbacks ||= { }
    end

    def err_feedbacks
      @@err_feedbacks ||= { }
    end

    # Here is the only method user can call inside the application (excepts start-up methods, of course).
    # You have to specify job_name and optionally its args and opts.
    # The method set initial arguments and send job to distributor which will send it to node.
    # Options are :after and :period (for deferred and periodic jobs), and :node to specify the preferred node to launch job.
    # Use :always_use_specified_node option to be sure that job will launched in the specified node.
    # Job itself will be a hash with the following keys:
    # name, args, make_after, last_error, run_at, failed_at, attempt, period, node, not_node, status, distributor, on_success, on_error.
    #
    # Simple job with arguments.
    # Arguments should be a Hash.
    # Arguments will be serialized using Marshal.dump before sending to node, so be sure that objects in args can be dumped.
    # (Do not use procs, objects with singleton methods, etc ... ).
    #
    # Example:
    # JR.enqueue 'job', {arg1: 'arg1', arg2: 'arg2'}
    #
    # You can add the following options:
    # :defer - run job in EM.defer block (in separate thread). Default is false.
    #  Be careful, the default threadpool size is 20 for EM.
    #  You can increase it by setting EM.threadpool_size = 'your value', but it is not recommended.
    # :run_at - run at given time;
    # :after - run after some time (in seconds);
    # :period - will make periodic job which will be launched every opts[:period] seconds;
    # :node - to send job to the specific node;
    # :not_node - to do not send job to the node;
    #
    # Example:
    # JR.enqueue 'job', {arg1: 'arg1'}, {period: 100, node: 'my_favorite_node', defer: true}
    # JR.enqueue 'job', {arg1: 'arg1'}, {after: 10, not_node: 'some_node'}
    #
    # You can add 'success feedback' and 'error feedback'. We use term 'feedback' to distinguish them from callbacks and errbacks which are executed on the node side.
    # These feedbacks are the procs. The first is 'success feedback', the second - 'error feedback'.
    # These feedback procs are called with 'job arguments' as arguments.
    #
    # Example:
    # success = proc { |args| result = args }
    # error = proc { |args| result = args }
    # JR.enqueue 'job', { arg1: 'arg1'}, {}, success, error
    #
    def enqueue(name, args = { }, opts = { }, success_proc = nil, error_proc = nil)
      hash = { 'name' => name, 'args' => args, 'attempt' => 0, 'status' => 'new', 'defer' => 'false' }

      hash.merge!('period' => opts[:period]) if opts[:period]
      opts[:after] = (opts[:run_at] - Time.now) if opts[:run_at]
      hash.merge!('make_after' => (opts[:after] || 0))

      hash.merge!('node' => opts[:node]) if opts[:node]
      hash.merge!('not_node' => opts[:not_node]) if opts[:not_node]

      hash.merge!('distributor' => JR::Distributor.server)

      hash.merge!('defer' => 'true') if opts[:defer]

      add_succ_feedbacks!(hash, success_proc) if success_proc.is_a? Proc
      add_err_feedbacks!(hash, error_proc) if error_proc.is_a? Proc

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
    #
    def make(hash) #new job is a Hash
      raise NoSuchJob unless jr_job = JR.jobs[hash['name']]

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
      distributor = JR::Distributor.server
      feedback_id = "#{distributor}_#{Time.now.utc.to_f}"
      succ_feedbacks.merge!(feedback_id => callback)
      hash.merge!('on_success' => feedback_id)
    end

    # Adds error callback which will launch when node reports error
    #
    def add_err_feedbacks!(hash, errback)
      distributor = JR::Distributor.server
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