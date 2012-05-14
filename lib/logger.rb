module JobReactor
  module Logger
################
#   To set output stream

    #mattr_writer :stdout #TODO

    def self.stdout
      @@stdout ||= $stdout
    end
#################
#   Is checked in dev_log

    @@development = false

    def self.development=(value)
      @@development = !!value
    end
#################

    # Log message to output stream
    #
    def self.log(msg)
      stdout.puts '-'*100
      stdout.puts(msg)
    end

    # Build string for job event and log it
    #
    def self.log_event(event, job)
      log("Log: #{event} #{job['name']}")
    end

    # Log if JR::Logger.development is set to true
    #
    def self.dev_log(msg)
      log(msg) if development?
    end

    # Is JR::Logger.development set to true?
    #
    def self.development?
      @@development
    end
  end
end