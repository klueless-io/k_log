# frozen_string_literal: true

require 'k_util'

module KLog
  # Log Structure is flexible logger for working through a complex object graph
  class LogStructure
    attr_reader :indent
    attr_reader :title
    attr_reader :title_type
    attr_reader :heading
    attr_reader :heading_type
    attr_reader :line_width
    attr_reader :graph
    attr_reader :formatter
    attr_reader :convert_data_to

    attr_reader :recursion_depth
    attr_reader :key_format
    attr_reader :graph_path
    attr_reader :graph_node

    attr_reader :lines
    attr_reader :output_as
    attr_reader :output_file

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
      @indent           = opts[:indent]             || '  '
      @title            = opts[:title]
      @title_type       = opts[:title_type]         || :heading

      @heading          = opts[:heading]
      @heading_type     = opts[:heading_type]       || :heading
      puts ':heading should be :title'              if opts[:heading]
      puts ':heading_type should be :title_type'    if opts[:heading_type]

      @formatter        = opts[:formatter]          || {}
      @graph            = parse_graph(opts[:graph]  || {})
      @convert_data_to  = opts[:convert_data_to]    || :raw # by default leave data as is

      @line_width       = opts[:line_width]         || 80
      @output_as        = opts[:output_as]          || [:console]
      @output_as        = [@output_as]              unless @output_as.is_a?(Array)
      @output_file      = opts[:output_file]

      @recursion_depth  = 0
      @key_format       = nil
      @graph_path       = []
      @lines            = []

      update_indent_label
    end

    def l
      @l ||= KLog::LogUtil.new(KLog.logger)
    end

    def log(data)
      log_heading(title, title_type) if title

      data = convert_data(data)

      log_data(data)

      add_line(KLog::LogHelper.line(line_width))

      render_output
    end

    def content
      @content ||= lines.join("\n")
    end

    def clean_content
      # remove color escape codes
      @clean_content ||= content.gsub(/\x1B\[\d*m/, '')
    end

    def clean_lines
      # remove color escape codes
      lines.flat_map { |line| line.gsub(/\x1B\[\d*m/, '').split("\n") }
    end

    def add_lines(lines)
      @lines += lines
    end

    def add_line(line)
      @lines << line
    end

    private

    # format_config = @formatter[:_root] if format_config.nil? && @recursion_depth.zero?

    def log_data(data)
      data.each_pair do |k, v|
        key = k.is_a?(String) ? k.to_sym : k

        graph_path.push(key)
        @graph_node = GraphNode.for(graph, graph_path)
        # l.kv 'key', "#{key.to_s.ljust(15)}#{graph_node.skip?.to_s.ljust(6)}#{@recursion_depth}"

        if graph_node.skip?
          # l.kv 'key', 'skipping...'
          @graph_path.pop
          next
        end

        value = graph_node.transform? ? graph_node.transform(v) : v

        case value
        when OpenStruct
          # l.kv 'go', 'open struct ->'
          log_structure(key, value)
          # l.kv 'go', 'open struct <-'
        when Array
          # l.kv 'go', 'array ->'
          log_array(key, value)
          # l.kv 'go', 'array <-'
        else
          # l.kv 'go', 'value ->'
          log_heading(graph_node.heading, graph_node.heading_type) if graph_node.heading
          add_line KLog::LogHelper.kv "#{@indent_label}#{key}", value
          # l.kv 'go', 'value <-'
        end

        # l.line
        # @graph_node = graph.for_path(graph_path)
        # l.line
        @graph_path.pop
      end
      nil
    end

    def log_structure(key, value)
      log_heading(graph_node.heading, graph_node.heading_type) if graph_node.heading
      add_line(KLog::LogHelper.green("#{@indent_label}#{key}"))
      log_child_data(value)
    end

    def log_child_data(value)
      depth_down
      log_data(value)
      depth_up
    end

    # rubocop:disable Metrics/AbcSize
    def log_array(key, array)
      # return if items.length.zero? && graph_node.skip_empty?

      items = array.clone
      items.select! { |item| graph_node.filter(item) }  if graph_node.filter?
      items = items.take(graph_node.take)               if graph_node.limited?
      items.sort!(&graph_node.sort)                     if graph_node.sort?

      return if items.length.zero? && graph_node.skip_empty?

      log_heading(graph_node.heading, graph_node.heading_type) if graph_node.heading

      if primitive?(items)
        add_line KLog::LogHelper.kv "#{@indent_label}#{key}", items.map(&:to_s).join(', ')
      else
        table_print items, tp_columns(items)
      end
    rescue StandardError => e
      # binding
    end
    # rubocop:enable Metrics/AbcSize
    
    def table_print(items, columns)
      io = TablePrintIo.new(self)

      tp.set :io, io
      tp items, columns
      tp.clear :io
    end

    def primitive?(items)
      item = items.first
      KUtil.data.basic_type?(item)
    end

    def log_heading(heading, heading_type)
      add_lines(KLog::LogHelper.dynamic_heading(heading, size: line_width, type: heading_type))
    end

    def tp_columns(items)
      # Use configured array columns
      return graph_node.columns if graph_node.columns

      # Slow but complete list of keys
      # items.flat_map { |v| v.to_h.keys }.uniq

      items.first.to_h.keys
    end

    def update_indent_label
      # puts "indent_label: #{indent} - #{@recursion_depth} - #{(indent * @recursion_depth)}"
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
      update_indent_label
    end

    def depth_up
      @recursion_depth = recursion_depth - 1
      update_indent_label
    end

    def render_output
      puts content                            if output_as.include?(:console)
      File.write(output_file, clean_content)  if output_as.include?(:file) && output_file
    end

    # convert_data_to: :open_struct
    def convert_data(data)
      return KUtil.data.to_open_struct(data)  if convert_data_to == :open_struct

      data
    end

    def parse_graph(data)
      if data.is_a?(Hash)
        transform_hash = data.each_with_object({}) do |(key, value), new_hash|
          if key == :columns && value.is_a?(Array)
            # Don't transform the table_print GEM columns definition as it must stay as a hash
            new_hash[key] = value
          else
            new_hash[key] = parse_graph(value)
          end
        end
        
        return OpenStruct.new(transform_hash.to_h)
      end

      return data.map { |o| parse_graph(o) }                               if data.is_a?(Array)
      return parse_graph(data.to_h)                                        if data.respond_to?(:to_h) # hash_convertible?(data)

      # Some primitave type: String, True/False or an ObjectStruct
      data
    end

    # def hash_convertible?(value)
    #   # Nil is a special case, it responds to :to_h but generally
    #   # you only want to convert nil to {} in specific scenarios
    #   return false if value.nil?

    #   value.is_a?(Array) ||
    #     value.is_a?(Hash) ||
    #     value.is_a?(Struct) ||
    #     value.is_a?(OpenStruct) ||
    #     value.respond_to?(:to_h)
    # end

    # Format configuration for a specific key
    #
    # @example Example configuration for key: tables
    #
    # configuration = {
    #   tables: {
    #     heading: 'Database Tables',
    #     take: :all,
    #     columns: [
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

    # Override table_print IO stream so that it writes into the structure
    class TablePrintIo
      def initialize(log_structure)
        @log_structure = log_structure
      end

      def puts(line)
        @log_structure.add_line(line)
      end
    end

    class GraphNode
      attr_accessor :config

      class << self
        def null
          @null ||= OpenStruct.new
        end

        def for(graph, graph_path)
          # node_config = graph_path.inject(graph, :send) # (uses deep nesting, but fails when nil is returned) https://stackoverflow.com/questions/15862455/ruby-nested-send
          # node.nil? ? null : node.send(name) || null
          node_config = graph_path.reduce(graph) do |node, name|
            result = node.send(name)
      
            break null if result.nil?

            result
          end

          new(node_config)
        end
      end

      def initialize(config)
        @config = config || OpenStruct.new
      end

      # table_print compatible configuration for displaying columns for an array
      def columns
        config.columns
      end

      # Optional heading for the node
      def heading
        config.heading
      end

      # Type of heading [:heading, :subheading, :section]
      def heading_type
        config.heading_type || :section
      end

      # Node data is to be transformed
      def transform?
        config&.transform.respond_to?(:call)
      end

      # Transform node value
      def transform(value)
        config.transform.call(value)
      end

      # Array rows are filtered
      def filter?
        config&.filter.respond_to?(:call)
      end

      # Array rows are filtered via this predicate
      def filter(value)
        config.filter.call(value)
      end

      # How any array rows to take
      def take
        config.take
      end

      # Array rows are limited, see take
      def limited?
        config.take&.is_a?(Integer)
      end

      # Array rows are sorted using .sort
      def sort?
        config&.sort.respond_to?(:call)
      end

      # Use array.sort?
      def sort
        config.sort
      end

      # Skip this node
      def skip?
        config.skip == true
      end

      # Skip empty array node (my be useful for other nodes, but not yet)
      def skip_empty?
        config.skip_empty == true
      end
    end
  end
end
