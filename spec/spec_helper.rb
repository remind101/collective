require 'webmock/rspec'

require 'dotenv'
Dotenv.load('.env.test')


# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :rspec

  config.raise_errors_for_deprecations!

  # Allow RSpec to run focused specs
  config.filter_run_including focus: true
  config.filter_run_excluding broken: true
  config.filter_run_excluding :bollocksed
  config.run_all_when_everything_filtered = true
  config.fail_fast = false
  config.before focus: true do
    fail "Hey dummy, don't commit focused specs." if ENV['CI']
  end
end
