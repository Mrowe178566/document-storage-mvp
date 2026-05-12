require "rspec-html-matchers"
require "webmock/rspec"
require "#{File.expand_path("../support/webmock", __FILE__)}"

RSpec.configure do |config|
  config.include RSpecHtmlMatchers
  config.example_status_persistence_file_path = "examples.txt"

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
