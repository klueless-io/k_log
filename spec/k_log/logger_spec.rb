# frozen_string_literal: true

require 'spec_helper'

KLog.logger = Logger.new($stdout)
KLog.logger.level = Logger::DEBUG
KLog.logger.formatter = KLog::LogFormatter.new

L = KLog::LogUtil.new(KLog.logger)

RSpec.describe 'Logger' do
  it do
    KLog::LogUtil.examples
  end
end
