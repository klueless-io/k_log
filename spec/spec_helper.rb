# frozen_string_literal: true

require 'pry'
require 'bundler/setup'
require 'rspec/collection_matchers'
require 'support/use_temp_folder'
require 'k_log'
require 'dry-struct'

module Types
  include Dry.Types()
end

# require 'k_usecases'
def normalize(obj)
  case obj
  when Hash
    obj.transform_keys(&:to_sym).transform_values { |v| normalize(v) }
  when Array
    obj.map { |item| normalize(item) }
  else
    obj
  end
end

def normalize_hash_output(str)
  str.gsub(/:(\w+)\s*=>/, '\1:')
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'
  config.filter_run_when_matching :focus

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # # ----------------------------------------------------------------------
  # # Usecase Documentor
  # # ----------------------------------------------------------------------

  # KUsecases.configure(config)

  # config.extend KUsecases

  # config.before(:context, :usecases) do
  #   puts '-' * 70
  #   puts self.class
  #   puts '-' * 70
  #   @documentor = KUsecases::Documentor.new(self.class)
  # end

  # config.after(:context, :usecases) do
  #   @documentor.render
  #   puts '-' * 70
  #   puts self.class
  #   puts '-' * 70
  # end
end
