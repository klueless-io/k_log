# frozen_string_literal: true

require 'spec_helper'
require 'k_log/examples'
require 'k_log/tools/build_formatter_configuration_for_log_structure'
require 'json'

RSpec.describe KLog::Tools::BuildFormatterConfigurationForLogStructure do
  let(:instance) { described_class.new }
  let(:json) { File.read(file) }
  let(:data) { JSON.parse(json) }

  describe 'examples' do
    subject { instance.build_sample_config(data) }

    let(:file) { 'spec/data/db_schema.json' }

    it 'print configuration' do
      subject
    end
  end
end
