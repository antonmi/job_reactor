require 'simplecov'
SimpleCov.start

def setup_environment
  RSpec.configure do |config|
    config.mock_with :rspec
  end
end