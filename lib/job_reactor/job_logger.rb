module JobReactor
  module JobLogger

    # Sets the output stream
    #
    def self.logger_method
      @logger_method ||= JR.config[:logger_method]
    end

    def self.stdout=(value)
      @stdout = value
    end

    def self.stdout
      @stdout ||= $stdout
    end

    # Logs message to output stream
    #
    def self.log(msg)
      if logger_method
        stdout.public_send(logger_method, "-----#{Time.now.utc}-----")
        stdout.public_send(logger_method, msg)
      end
    end

    # Builds string for job event and log it
    #
    def self.log_event(event, job)
      log("#{event} '#{job['name']}'")
    end

  end
end