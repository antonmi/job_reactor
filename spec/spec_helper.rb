require 'simplecov'
SimpleCov.start

Dir[File.expand_path('../support/*', __FILE__)].each do |f|
  require f
end

def setup_environment
  RSpec.configure do |config|
    config.mock_with :rspec
  end
end
