# frozen_string_literal: true

module KDsl
  module Logger
    # Styled Log formatter
    class LogFormatter < ::Logger::Formatter
      attr_accessor :show_caller

      SEVERITY_TO_COLOR_MAP = {
        'DEBUG' => '34',
        'INFO' => '32',
        'WARN' => '33',
        'ERROR' => '31',
        'FATAL' => '37'
      }.freeze

      def call(severity, _timestamp, _progname, msg)
        severity = severity.upcase

        color = SEVERITY_TO_COLOR_MAP[severity]

        severity_value = format("\033[#{color}m%<severity>-5.5s\033[0m", { severity: severity })

        msg = msg.is_a?(String) ? msg : msg.inspect

        format(
          "%<time>s %<severity>s %<message>s\n", {
            time: Time.now.strftime('%d|%H:%M:%S'),
            severity: severity_value,
            message: msg
          }
        )
      end
    end
  end
end
