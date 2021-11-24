# frozen_string_literal: true

module KLog
  class Examples
    include KLog::Logging

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def examples
      examples_simple
      examples_complex
    end

    def examples_simple
      log.debug 'some debug message'
      log.info 'some info message'
      log.warn 'some warning message'
      log.error 'some error message'
      log.fatal 'some fatal message'

      log.kv('First Name', 'David')
      log.kv('Last Name', 'Cruwys')
      log.kv('Age', 45)
      log.kv('Sex', 'male')

      log.heading('Heading')
      log.subheading('Sub Heading')
      log.section_heading('Section Heading')

      data = OpenStruct.new
      data.title = 'Software Architect'
      data.age = 45
      data.name = 'David'
      data.names = %w[David Bill]
      data.status = :debug
      data.statuses = %i[debug info blah]
      log.open_struct(data, section_heading: 'Display Open Struct')
    end

    def examples_complex
      log.block ['Line 1', 12, 'Line 3', true, 'Line 5']

      log.progress(0, 'Section 1')
      log.progress
      log.progress
      save_progress = log.progress

      log.progress(10, 'Section 2')
      log.progress
      log.progress
      log.progress

      log.progress(save_progress, 'Section 1')
      log.progress
      log.progress
      log.progress

      log.line
      log.line(20)
      log.line(20, character: '-')

      yaml1 = {}
      yaml1['title'] = 'Software Architect'
      yaml1['age'] = 45
      yaml1['name'] = 'David'

      yaml3 = {}
      yaml3['title'] = 'Developer'
      yaml3['age'] = 20
      yaml3['name'] = 'Jin'

      log.yaml(yaml1)

      yaml2 = OpenStruct.new
      yaml2.title = 'Software Architect'
      yaml2.age = 45
      yaml2.name = 'David'

      log.yaml(yaml2)

      mixed_yaml_array = [yaml1, yaml2]

      # This fails because we don't correctly pre-process the array
      log.yaml(mixed_yaml_array)

      hash_yaml_array = [yaml1, yaml3]

      log.yaml(hash_yaml_array)

      begin
        raise 'Here is an error'
      rescue StandardError => e
        log.exception(e)
      end
      begin
        raise 'Here is an error'
      rescue StandardError => e
        log.exception(e, style: :message)
      end
      begin
        raise 'Here is an error'
      rescue StandardError => e
        log.exception(e, style: :short)
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
