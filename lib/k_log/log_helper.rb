# frozen_string_literal: true

# Log Helper is an internal class that takes care of a lot of the formating of different content types
# e.g key/values, lines, progress counters and headings
# it is different to the formatter becuase the formatter is used by Rails Logger to change the output stream style and format
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

    unless section.nil?
      # Pl.info 'here'
      @progress_section = section
    end

    # puts '@progress_position'
    # puts @progress_position
    # puts '@progress_section'
    # puts @progress_section

    section_length = 28

    section = if @progress_section.nil?
                ' ' * section_length
              else
                ' ' + @progress_section.ljust(section_length - 1, ' ')
              end

    # puts 'section'
    # puts section

    result = '..' + section + ':' + @progress_position.to_s.rjust(4)

    @progress_position += 1

    result
  end

  def self.line(size = 70, character = '=')
    green(character * size)
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
    heading = "[ #{heading} ]"
    line = line(size - heading.length, '-')

    # It is important that you set the colour after you have calculated the size
    "#{green(heading)}#{line}"
  end

  # :sql_array should be an array with SQL and values
  # example: L.sql(["name = :name and group_id = :value OR parent_id = :value", name: "foo'bar", value: 4])
  # def sql(sql_array)
  #   value = ActiveRecord::Base.send(:sanitize_sql_array, sql_array)

  #   info(value)
  # end

  # rubocop:disable Metrics/CyclomaticComplexity
  def self.block(messages, include_line = true, title: nil)
    result = include_line ? [line] : []

    unless title.nil?
      result.push(title)
      result.push(line(70, ','))
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

  def self.green(value)
    "\033[32m#{value}\033[0m"
  end
end
