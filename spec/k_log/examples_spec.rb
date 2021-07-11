# frozen_string_literal: true

require 'spec_helper'
require 'k_log/examples'

RSpec.describe KLog::Examples do
  let(:instance) { described_class.new }
  let(:log) { KLog::LogUtil.new(KLog.logger) }

  context 'kv_hash' do
    let(:data) do
      {
        key1: '1',
        key3: '3',
        key2: '2',
        key4: '4',
        key5: '5',
        key6: '6'
      }
    end

    it { log.kv_hash(data) }
  end

  it 'simple examples' do
    instance.examples_simple
  end

  # it 'complex examples' do
  #   instance.examples_complex
  # end
end
