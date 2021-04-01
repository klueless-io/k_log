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

  def self.default_logger
    return @default_logger if defined? @default_logger
    @default_logger = begin
      logger = Logger.new($stdout)
      logger.level = Logger::DEBUG
      logger.formatter = KLog::LogFormatter.new
      KLog::LogUtil.new(logger)
    end      
  end
end

puts "KLog::Version: #{KLog::VERSION}" if ENV['KLUE_DEBUG']&.to_s&.downcase == 'true'
