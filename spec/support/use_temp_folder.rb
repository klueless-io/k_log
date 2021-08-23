# frozen_string_literal: true

RSpec.shared_context :use_temp_folder do |debug = false|
  around do |example|
    Dir.mktmpdir('rspec-') do |folder|
      @temp_folder = folder

      if debug
        puts '-' * 70
        puts @temp_folder
        puts '-' * 70
      end

      example.run
    end
  end
end
