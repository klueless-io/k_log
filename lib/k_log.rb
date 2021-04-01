# frozen_string_literal: true

require 'logger'
require 'table_print'
require 'k_log/version'
require 'k_log/log_formatter'
require 'k_log/log_helper'
require 'k_log/log_util'

# Simple console log helpers
module KLog
  # raise KLog::Error, 'Sample message'
  class Error < StandardError; end

  class << self
    attr_accessor :logger
  end
end

# KLog.logger = Logger.new($stdout)
# KLog.logger.level = Logger::DEBUG
# KLog.logger.formatter = KLog::LogFormatter.new

# L = KLog::LogUtil.new(KLog.logger)
