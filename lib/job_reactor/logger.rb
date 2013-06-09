module JobReactor
  module Logger

    # Sets the output stream
    #
    @logger_method = JR.config[:logger_method]

    def self.stdout=(value)
      @stdout = value
    end

    def self.stdout
      @stdout ||= $stdout
    end

    # Logs message to output stream
    #
    def self.log(msg)
      stdout.public_send(@logger_method, '-'*100)
      stdout.public_send(@logger_method, msg)
    end

    # Builds string for job event and log it
    #
    def self.log_event(event, job)
      log("#{event} '#{job['name']}'")
    end

  end
end