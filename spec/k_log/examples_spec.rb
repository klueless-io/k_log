# frozen_string_literal: true

require 'spec_helper'
require 'k_log/examples'

RSpec.describe KLog::Examples do
  let(:instance) { described_class.new }
  let(:log) { KLog::LogUtil.new(KLog.logger) }

  it 'examples' do
    instance.examples
  end
end
