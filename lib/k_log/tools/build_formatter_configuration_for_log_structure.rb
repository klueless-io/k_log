# frozen_string_literal: true

require 'k_util'

module KLog
  module Tools
    # This tool will build a Log Structure Formatter configuration by working
    # through the object graph you would like to use with Log Structure
    class BuildFormatterConfigurationForLogStructure
      # Build a sample configuration based on the structure
      def build_sample_config(data)
        open_struct_data = KUtil.data.to_open_struct(data)

        lines = [
          '# Usage:',
          '',
          "formatter = #{infer_config(open_struct_data)}",
          '',
          "log.structure(data, heading: 'Insert Heading', line_width: 150, formatter: formatter)"
        ]
        KLog.logger.line
        puts lines
        KLog.logger.line
      end

      private

      def infer_config(data)
        result = {}

        data.each_pair do |key, value|
          next unless value.is_a?(Array)
          next if KUtil.data.basic_type?(value.first)

          result[key] = {
            heading: key.to_s,
            take: :all,
            array_columns: value.first.to_h.keys
          }
        end

        # This is essentially a pretty hash
        JSON.pretty_generate(result)
            .gsub(/(?:"|')(?<key>[^"]*)(?:"|')(?=:)(?::)/) do |_|
          "#{Regexp.last_match(:key)}:"
        end
            .gsub('take: "all"', 'take: :all')
      end
    end
  end
end
