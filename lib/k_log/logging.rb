# frozen_string_literal: true

module KLog
  module Logging
    def log
      @log ||= KLog.logger
    end
  end
end
