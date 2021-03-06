# frozen_string_literal: true

# Log Helper is an internal class that takes care of a lot of the formatting
# of different content types e.g key/values, lines, progress counters and headings
# it is different to the formatter because the formatter is used by Rails Logger
# to change the output stream style and format
module KLog
  # Simple console log helpers
  class LogHelper
    @progress_section = ''
    @progress_position = 0

    class << self
      attr_accessor :progress_position
      attr_accessor :progress_section
    end

    def self.kv(key, value, key_width = 30)
      "#{green(key.to_s.ljust(key_width))}: #{value}"
    end

    def self.progress(pos = nil, section = nil)
      @progress_position = pos.nil? ? @progress_position : pos

      @progress_section = section unless section.nil?

      section_length = 28

      section = if @progress_section.nil?
                  ' ' * section_length
                else
                  " #{@progress_section.ljust(section_length - 1, ' ')}"
                end

      result = "..#{section}:#{@progress_position.to_s.rjust(4)}"

      @progress_position += 1

      result
    end

    def self.line(size = 70, character = '=')
      green(character * size)
    end

    def self.dynamic_heading(heading, size: 70, type: :heading)
      return heading(heading, size)           if type == :heading
      return subheading(heading, size)        if type == :subheading
      return [section_heading(heading, size)] if %i[section_heading section].include?(type)

      []
    end

    def self.heading(heading, size = 70)
      line = line(size)

      [
        line,
        heading,
        line
      ]
    end

    def self.subheading(heading, size = 70)
      line = line(size, '-')
      [
        line,
        heading,
        line
      ]
    end

    # A section heading
    #
    # example:
    # [ I am a heading ]----------------------------------------------------
    def self.section_heading(heading, size = 70)
      brace_open = green('[ ')
      brace_close = green(' ]')
      line_length = size - heading.length - 4
      line = line_length.positive? ? line(line_length, '-') : ''

      # It is important that you set the colour after you have calculated the size
      "#{brace_open}#{heading}#{brace_close}#{green(line)}"
    end

    # :sql_array should be an array with SQL and values
    # example: L.sql(["name = :name and group_id = :value OR parent_id = :value", name: "foo'bar", value: 4])
    # def sql(sql_array)
    #   value = ActiveRecord::Base.send(:sanitize_sql_array, sql_array)

    #   info(value)
    # end

    # rubocop:disable Metrics/CyclomaticComplexity
    def self.block(messages, include_line: true, title: nil)
      result = include_line ? [line] : []

      unless title.nil?
        result.push(title)
        result.push(line(70, '-'))
      end

      result.push messages if messages.is_a?(String) || messages.is_a?(Integer)

      if messages.is_a? Array
        messages.each do |message|
          result.push message
        end
      end

      result.push line if include_line

      result
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def self.red(value)
      "\033[31m#{value}\033[0m"
    end

    def self.green(value)
      "\033[32m#{value}\033[0m"
    end

    def self.yellow(value)
      "\033[33m#{value}\033[0m"
    end

    def self.blue(value)
      "\033[34m#{value}\033[0m"
    end

    def self.purple(value)
      "\033[35m#{value}\033[0m"
    end

    def self.cyan(value)
      "\033[36m#{value}\033[0m"
    end

    def self.grey(value)
      "\033[37m#{value}\033[0m"
    end

    def self.bg_red(value)
      "\033[41m#{value}\033[0m"
    end

    def self.bg_green(value)
      "\033[42m#{value}\033[0m"
    end

    def self.bg_yellow(value)
      "\033[43m#{value}\033[0m"
    end

    def self.bg_blue(value)
      "\033[44m#{value}\033[0m"
    end

    def self.bg_purple(value)
      "\033[45m#{value}\033[0m"
    end

    def self.bg_cyan(value)
      "\033[46m#{value}\033[0m"
    end

    def self.bg_grey(value)
      "\033[47m#{value}\033[0m"
    end
  end
end
