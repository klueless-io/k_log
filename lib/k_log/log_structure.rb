# frozen_string_literal: true

require 'k_util'

module KLog
  # Log Structure is flexible logger for working through a complex object graph
  class LogStructure
    attr_accessor :indent
    attr_accessor :heading
    attr_accessor :heading_type
    attr_accessor :line_width
    attr_accessor :formatter
    attr_accessor :skip_array

    attr_accessor :recursion_depth
    attr_accessor :key_format

    # Log a structure
    #
    # Can handle Hash, Array, OpenStruct, Struct, DryStruct, Hash convertible custom classes
    #
    # @option opts [String] :indent Indent with string, defaults to '  '
    # @option opts [String] :heading Log heading using logger.dynamic_heading
    # @option opts [String] :heading_type :heading, :subheading, :section_heading
    # @option opts [String] :line_width line width defaults to 80, but can be overridden here
    # @option opts [String] :formatter is a complex configuration for formatting different data within the structure
    def initialize(opts)
      @indent           = opts[:indent] || '  '
      @heading          = opts[:heading]
      @heading_type     = opts[:heading_type] || :heading
      @formatter        = opts[:formatter] || {}

      @line_width       = opts[:line_width] || 80
      # @skip_array = opts[:skip_array]

      @recursion_depth  = 0
      @key_format       = nil
      update_indent_label
    end

    def log(data)
      log_heading(heading, heading_type)

      open_struct_data = KUtil.data.to_open_struct(data)

      log_data(open_struct_data)

      KLog.logger.line(line_width)
    end

    # Build a sample configuration based on the structure (move to own class)
    def build_sample_config(_data)
      # open_struct_data = KUtil.data.to_open_struct(data)
      {
        to: :do
      }
    end

    private

    def build_key_format(key)
      format_config = @formatter[key]
      format_config = @formatter[:_root] if format_config.nil? && @recursion_depth.zero?
      @key_format = KeyFormat.new(format_config)
    end

    def log_data(data)
      data.each_pair do |key, value|
        build_key_format(key)
        case value
        when OpenStruct
          log_structure(key, value) unless @key_format.ignore?
        when Array
          log_array(key, value)     unless @key_format.ignore?
        else
          KLog.logger.kv "#{@indent_label}#{key}", value
        end
      end
      nil
    end

    def log_structure(key, value)
      # This is specifically for k_doc, I should use a configuration instead of this technique
      if value['rows'].is_a?(Array)
        # KLog.logger.subheading(key)
        # opts[:subheading] = key
        # opts.delete(:subheading)
      else
        KLog.logger.kv "#{@indent_label}#{key}", ''
      end
      log_child_data(value)
    end

    def log_child_data(value)
      depth_down
      update_indent_label
      # indent_in
      log_data(value)
      update_indent_label
      # indent_out
      depth_up
    end

    # rubocop:disable Metrics/AbcSize
    def log_array(key, array)
      # next unless opts[:skip_array].nil?
      return unless array.length.positive?

      log_heading(key_format.heading, key_format.heading_type)

      filter_items = key_format.take_all ? array : array.take(key_format.take)

      if primitive?(filter_items)
        KLog.logger.kv "#{indent}#{key}", filter_items.map(&:to_s).join(', ')
      else
        tp filter_items, tp_columns(filter_items)
      end
    end
    # rubocop:enable Metrics/AbcSize

    def primitive?(items)
      item = items.first
      KUtil.data.basic_type?(item)
    end

    def log_heading(heading, heading_type)
      return unless heading

      KLog.logger.dynamic_heading(heading, size: line_width, type: heading_type)
    end

    def tp_columns(items)
      # Use configured array columns
      return key_format.array_columns if key_format.array_columns

      # Slow but complete list of keys
      # items.flat_map { |v| v.to_h.keys }.uniq

      items.first.to_h.keys
    end

    def update_indent_label
      @indent_label = (indent * @recursion_depth)
    end

    def indent_in
      @indent = "#{@indent}  "
    end

    def indent_out
      @indent = indent.chomp('  ')
    end

    def depth_down
      @recursion_depth = recursion_depth + 1
    end

    def depth_up
      @recursion_depth = recursion_depth - 1
    end

    # Format configuration for a specific key
    #
    # @example Example configuration for key: tables
    #
    # configuration = {
    #   tables: {
    #     heading: 'Database Tables',
    #     take: :all,
    #     array_columns: [
    #       :name,
    #       :force,
    #       :primary_key,
    #       :id,
    #       columns: { display_method: lambda { |row| row.columns.map { |c| c.name }.join(', ') }, width: 100 }
    #     ]
    #   },
    #   people: {
    #     ... people configuration goes here
    #   }
    # }
    #
    # format = KeyFormat.new(configuration[:tables])
    class KeyFormat
      attr_accessor :config

      def initialize(config)
        @config = OpenStruct.new(config)
      end

      def array_columns
        config.array_columns
      end

      def heading
        config.heading
      end

      def heading_type
        config.heading_type || :section_heading
      end

      def take
        config.take
      end

      def take_all
        config.take.nil? || config.take == :all
      end

      def ignore?
        config.ignore == true
      end
    end
  end
end
