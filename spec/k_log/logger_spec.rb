# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Logger' do
  it do
    require 'k_log'
    KLog::LogUtil.examples
  end
end
