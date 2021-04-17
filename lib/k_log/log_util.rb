# frozen_string_literal: true

# Format Logger Util provides static helper methods that delegate responsibility
# to the underlying Format Logger, you can use the Util instead Rails.logger so
# that you have access to IDE intellisense around available methods and so you
# can use the same logger calls from controllers/models which normally have
# access to to a logger variable and services which do not have access to a
# logger variable
#
# I usually alias the call to LogUtil by doing L = LogUtil

# require_relative 'format_logger'
# require_relative 'format_logger_helper'

module KLog
  # Simple console log helpers
  class LogUtil
    def initialize(logger)
      @logger = logger
    end

    # include ActiveSupport::LoggerThreadSafeLevel
    # include LoggerSilence

    #----------------------------------------------------------------------------------------------------
    # Standard Accessors that are on the standard rails Logger
    #----------------------------------------------------------------------------------------------------
    def debug(value)
      @logger.debug(value)
    end

    def info(value)
      @logger.info(value)
    end

    def warn(value)
      @logger.warn(value)
    end

    def error(value)
      @logger.error(value)
    end

    def fatal(value)
      @logger.fatal(value)
    end

    #----------------------------------------------------------------------------------------------------
    # Helper Log output Methods
    #----------------------------------------------------------------------------------------------------

    # Write a Key/Value Pair
    # Need to change this to named_param
    def kv(key, value, key_width = 30)
      message = LogHelper.kv(key, value, key_width)
      @logger.info(message)
    end

    # Write a progress point, progress will update on it's own
    def progress(pos = nil, section = nil)
      message = LogHelper.progress(pos, section)
      # @logger.debug(message)
      @logger.info(message)

      LogHelper.progress_position
    end

    # prints out a line to the log
    def line(size = 70, character: '=')
      message = LogHelper.line(size, character)

      @logger.info(message)
    end

    def heading(heading, size = 70)
      lines = LogHelper.heading(heading, size)
      info_multi_lines(lines)
    end

    def subheading(heading, size = 70)
      lines = LogHelper.subheading(heading, size)

      info_multi_lines(lines)
    end

    # A section heading
    #
    # example:
    # [ I am a heading ]----------------------------------------------------
    def section_heading(heading, size = 70)
      heading = LogHelper.section_heading(heading, size)

      info(heading)
    end

    def block(messages, include_line: true, title: nil)
      lines = LogHelper.block(messages, include_line: include_line, title: title)

      info_multi_lines(lines)
    end

    # # :sql_array should be an array with SQL and values or with SQL and Hash
    # # example:
    # #   KLog.logger.sql(["name = :name and group_id = :value OR parent_id = :value", name: "foo'bar", value: 4])
    # #   KLog.logger.sql([sql_exact_match_skills_in_use, {names: self.segments_container.segment_values}])
    # def sql(sql_array)
    #   value = ActiveRecord::Base.send(:sanitize_sql_array, sql_array)

    #   info(value)
    # end

    def yaml(data, is_line: true)
      require 'yaml'
      line if is_line

      @logger.info(data.to_yaml) if data.is_a?(Hash)

      @logger.info(data.marshal_dump.to_yaml) if data.is_a?(OpenStruct)

      if data.is_a? Array
        data.each do |d|
          @logger.info(d.to_yaml)
        end
      end

      line if is_line
    end

    def json(data)
      @logger.info(JSON.pretty_generate(data))
    end
    alias j json

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/AbcSize
    def open_struct(data, indent = '', **opts)
      data.each_pair do |key, value|
        case value
        when OpenStruct
          if value['rows'].is_a?(Array)
            # KLog.logger.subheading(key)
            opts[:subheading] = key
            open_struct(value, indent, **opts)
            opts.delete(:subheading)
          else
            KLog.logger.kv "#{indent}#{key}", ''
            indent = "#{indent}  "
            open_struct(value, indent, **opts)
            indent = indent.chomp('  ')
          end
        when Array
          next unless opts[:skip_array].nil?

          puts LogHelper.section_heading(opts[:subheading], 88) unless opts[:subheading].nil?

          if value.length.positive?
            if value.first.is_a?(String)
              KLog.logger.kv "#{indent}#{key}", value.join(', ')
            else
              tp value, value.first.to_h.keys
            end
          end
        else
          KLog.logger.kv "#{indent}#{key}", value
        end
      end
      nil
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/AbcSize
    alias ostruct open_struct
    alias o open_struct

    def exception(exception)
      line

      @logger.info(exception.message)
      @logger.info(exception.backtrace.join("\n"))

      line
    end

    #----------------------------------------------------------------------------------------------------
    # Pretty Loggers
    #----------------------------------------------------------------------------------------------------

    # NOTE: using  pretty_inspect is an existing namespace conflict
    # rubocop:disable Metrics/AbcSize
    def pretty_class(instance)
      c = instance.class

      line

      kv('Full Class', c.name)
      kv('Module', c.name.deconstantize)
      kv('Class', c.name.demodulize)

      source_location = c.instance_methods(false).map do |m|
        c.instance_method(m).source_location.first
      end.uniq

      begin
        kv('Source Location', source_location)
      rescue StandardError => e
        warn e
      end

      line
    end
    # rubocop:enable Metrics/AbcSize

    def kv_hash(hash)
      hash.each do |key, value|
        kv(key, value)
      end
    end

    # NOTE: using  pretty_inspect is an existing namespace conflict
    def pretty_params(params)
      line

      params.each do |k, v|
        if params[k].is_a?(Hash)

          params[k].each do |child_k, child_v|
            kv("#{k}[#{child_k}]", child_v)
          end

        else
          kv(k, v)
        end
      end

      line
    end

    def help_all_symbols
      # Produces a lot of data, need some sort of filter I think before this is useful
      Symbol.all_symbols.each do |s|
        info s
        # debug s
      end
    end

    def visual_compare_hashes(hash1, hash2)
      content1 = JSON.pretty_generate(hash1)
      content2 = JSON.pretty_generate(hash2)

      file1 = Tempfile.new('hash1')
      file1.write(content1)
      file1.close

      file2 = Tempfile.new('hash2')
      file2.write(content2)
      file2.close

      system "code --diff #{file1.path} #{file2.path}"

      # Provide enough time for vscode to open and display the files before deleting them
      sleep 1

      file1.unlink
      file2.unlink
    end

    #----------------------------------------------------------------------------------------------------
    # Internal Methods
    #----------------------------------------------------------------------------------------------------

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def self.examples
      examples_simple
      # examples_complex
    end

    def self.examples_simple
      KLog.logger.debug 'some debug message'
      KLog.logger.info 'some info message'
      KLog.logger.warn 'some warning message'
      KLog.logger.error 'some error message'
      KLog.logger.fatal 'some fatal message'

      KLog.logger.kv('First Name', 'David')
      KLog.logger.kv('Last Name', 'Cruwys')
      KLog.logger.kv('Age', 45)
      KLog.logger.kv('Sex', 'male')

      KLog.logger.heading('Heading')
      KLog.logger.subheading('Sub Heading')
      KLog.logger.section_heading('Section Heading')
    end

    def self.examples_complex
      KLog.logger.block ['Line 1', 12, 'Line 3', true, 'Line 5']

      KLog.logger.progress(0, 'Section 1')
      KLog.logger.progress
      KLog.logger.progress
      save_progress = KLog.logger.progress

      KLog.logger.progress(10, 'Section 2')
      KLog.logger.progress
      KLog.logger.progress
      KLog.logger.progress

      KLog.logger.progress(save_progress, 'Section 1')
      KLog.logger.progress
      KLog.logger.progress
      KLog.logger.progress

      KLog.logger.line
      KLog.logger.line(20)
      KLog.logger.line(20, character: '-')

      yaml1 = {}
      yaml1['title'] = 'Software Architect'
      yaml1['age'] = 45
      yaml1['name'] = 'David'

      yaml3 = {}
      yaml3['title'] = 'Developer'
      yaml3['age'] = 20
      yaml3['name'] = 'Jin'

      KLog.logger.yaml(yaml1)

      yaml2 = OpenStruct.new
      yaml2.title = 'Software Architect'
      yaml2.age = 45
      yaml2.name = 'David'

      KLog.logger.yaml(yaml2)

      mixed_yaml_array = [yaml1, yaml2]

      # This fails because we don't correctly pre-process the array
      KLog.logger.yaml(mixed_yaml_array)

      hash_yaml_array = [yaml1, yaml3]

      KLog.logger.yaml(hash_yaml_array)

      begin
        raise 'Here is an error'
      rescue StandardError => e
        KLog.logger.exception(e)
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    private

    def debug_multi_lines(lines)
      lines.each do |line|
        debug(line)
      end
    end

    def info_multi_lines(lines)
      lines.each do |line|
        info(line)
      end
    end

    def warn_multi_lines(lines)
      lines.each do |line|
        warn(line)
      end
    end

    def error_multi_lines(lines)
      lines.each do |line|
        error(line)
      end
    end

    def fatal_multi_lines(lines)
      lines.each do |line|
        fatal(line)
      end
    end
  end
end
