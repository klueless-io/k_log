# frozen_string_literal: true

# use this to debug any single test by rendering to file name, add [, true] to open in vscode
# fcontext { it_behaves_like(:write_file) }
# fcontext { it_behaves_like(:write_file); it { File.write('spec/k_log/a2.txt', expected_output.join("\n")) } }

require 'spec_helper'
require 'k_log/examples'
require 'complex_structure/root'
require 'json'

# { first_5_column_names: { width: 150, display_method: ->(row) { row.columns.take(5).map(&:name).join(', ') } } }
# Printing NON open_struct objects and having access to custom methods
# Transform array items (instead of full transform), is this needed
# Handle data namespace/option namespace conflicts
# Can array be done in details format?
# Improve colorization

RSpec.describe KLog::LogStructure do
  let(:instance) { described_class.new(**opts) }
  # let(:data) { File.rea }
  let(:input_folder) { 'spec/data' }
  let(:input_filename) { 'complex_structure.json' }
  let(:input_file) { File.join(input_folder, input_filename) }
  let(:json) { File.read(input_file) }

  let(:hash) { JSON.parse(json) }
  let(:hash_as_sym) { KUtil.data.deep_symbolize_keys(hash) }
  let(:hash_as_open_struct) { KUtil.data.to_open_struct(hash) }
  let(:hash_as_model) { ComplexStructure::Root.new(hash_as_sym) }

  let(:input) { hash }

  let(:output_folder) { '/Users/davidcruwys/dev/kgems/k_log/spec/k_log' }
  let(:output_filename) { 'a1.txt' }
  let(:output_file) { File.join(output_folder, output_filename) }

  let(:convert_data_to) { nil } # defaults to :raw     - valid values [:raw, :open_struct]
  # let(:output_as) { :file }           # defaults to :console - valid values [:console, :file, :none]
  let(:output_as) { nil } # defaults to :console - valid values [:console, :file, :none]
  # let(:output_as) { [:none] }
  let(:line_width) { nil }            # defaults to 80
  let(:key_width) { nil }             # defaults to 30
  let(:indent) { nil }                # defaults to '  '
  let(:title) { nil }                 # defaults to nil, is displayed when not nil
  let(:title_type) { nil }            # defaults to :heading - valid values [:heading, :subheading, :section]
  let(:show_array_count) { nil }      # defaults to nil - valid values: [nil, true, false]
  let(:graph) { nil }
  let(:opts) do
    {
      output_as: output_as,
      output_file: output_file,
      convert_data_to: convert_data_to,
      line_width: line_width,
      key_width: key_width,
      indent: indent,
      title: title,
      title_type: title_type,
      show_array_count: show_array_count,
      graph: graph
    }
  end

  shared_context :temp_dir do
    include_context :use_temp_folder

    let(:output_folder) { @temp_folder }
  end

  shared_examples :write_file do |vscode_open = false|
    let(:output_folder) { '/Users/davidcruwys/dev/kgems/k_log/spec/k_log' }
    let(:output_as) { [:file] }

    it { vscode_open ? vs(instance) : instance }
  end

  describe 'DATA SHAPES' do
    before { instance.log(input) }

    context 'when trying different input data types' do
      context 'the data transformation is consistent' do
        subject { hash_as_sym }

        let(:expected_output) { hash_as_sym }

        context 'when input is hash -> hash(:symbolized)' do
          let(:input) { hash_as_sym }
          it { is_expected.to eq(normalize_hash_string(expected_output)) }
        end

        context 'when input is OpenStruct -> hash(:symbolized)' do
          let(:input) { hash_as_open_struct }
          it { is_expected.to eq(normalize_hash_string(expected_output)) }
        end

        context 'when input is ComplexStructure::Root -> hash(:symbolized)' do
          let(:input) { hash_as_model }
          it { is_expected.to eq(normalize_hash_string(expected_output)) }
        end
      end

      # It would be better if this was NOT the case
      # for this to become consistent, I would need to:
      #   alter hashes to structures
      #   alter open_struct to structures in arrays
      #   alter dry_struct to structures in arrays
      # I'm not sure if this is achievable without side effect
      context 'the log output is different' do
        subject { instance.clean_lines }

        context 'when input is hash -> hash(:symbolized)' do
          let(:expected_output) do
            [
              'rails                         : 4',
              'complex                       : {:some=>"data", :some_more=>"data", :extra=>{:extra_info=>"info", :more_info=>"and more", :names=>["david", "was", "here"], :ages=>[23, 53, 64], :more_people=>[{:age=>45, :first_name=>"bob", :last_name=>"jane"}, {:age=>25, :first_name=>"sam", :last_name=>"sugar"}]}, :other_info=>"other"}',
              'FIRST_NAME | LAST_NAME | AGE | ACTIVE | CHILDREN                      ',
              '-----------|-----------|-----|--------|-------------------------------',
              'david      | cruwys    | 45  | true   | [{:name=>"Steven", :gender=...',
              'joh        | doe       | 38  | true   | [{:name=>"Alison", :gender=...',
              'lisa       | lou       | 23  | true   | []                            ',
              'amanda     | armor     | 29  | false  | [{:name=>"Fiona", :gender=>...',
              '================================================================================'
            ]
          end
          context 'when data is hash and convert_data_to: :raw' do
            let(:input) { hash_as_sym }
            it 'returns the expected output for hash input' do
             is_expected.to eq(normalize_hash_string(expected_output))
           end
          end
        end

        context 'when input is OpenStruct -> hash(:symbolized)' do
          let(:expected_output) do
            [
              'rails                         : 4',
              'complex',
              '  some                        : data',
              '  some_more                   : data',
              '  extra',
              '    extra_info                : info',
              '    more_info                 : and more',
              '    names                     : david, was, here',
              '    ages                      : 23, 53, 64',
              'AGE | FIRST_NAME | LAST_NAME',
              '----|------------|----------',
              '45  | bob        | jane     ',
              '25  | sam        | sugar    ',
              '  other_info                  : other',
              'FIRST_NAME | LAST_NAME | AGE | ACTIVE | CHILDREN                      ',
              '-----------|-----------|-----|--------|-------------------------------',
              'david      | cruwys    | 45  | true   | [#<OpenStruct name="Steven"...',
              'joh        | doe       | 38  | true   | [#<OpenStruct name="Alison"...',
              'lisa       | lou       | 23  | true   | []                            ',
              'amanda     | armor     | 29  | false  | [#<OpenStruct name="Fiona",...',
              '================================================================================'
            ]
          end
          context 'when data is OpenStruct and convert_data_to: :raw' do
            let(:input) { hash_as_open_struct }
            it 'returns the expected output for hash input' do
             is_expected.to eq(normalize_hash_string(expected_output))
           end
          end
          context 'when data is hash and convert_data_to: :open_struct' do
            let(:convert_data_to) { :open_struct }
            it 'returns the expected output for hash input' do
             is_expected.to eq(normalize_hash_string(expected_output))
           end
          end
        end

        context 'when input is ComplexStructure::Root -> hash(:symbolized)' do
          let(:input) { hash_as_model }
          let(:expected_output) do
            [
              'rails                         : 4',
              'complex',
              '  some                        : data',
              '  some_more                   : data',
              '  extra',
              '    extra_info                : info',
              '    more_info                 : and more',
              '    names                     : david, was, here',
              '    ages                      : 23, 53, 64',
              'AGE | FIRST_NAME | LAST_NAME',
              '----|------------|----------',
              '45  | bob        | jane     ',
              '25  | sam        | sugar    ',
              '  other_info                  : other',
              'AGE | FIRST_NAME | LAST_NAME | ACTIVE | CHILDREN                      ',
              '----|------------|-----------|--------|-------------------------------',
              '45  | david      | cruwys    | true   | [#<ComplexStructure::Childr...',
              '38  | joh        | doe       | true   | [#<ComplexStructure::Childr...',
              '23  | lisa       | lou       | true   | []                            ',
              '29  | amanda     | armor     | false  | [#<ComplexStructure::Childr...',
              '================================================================================'
            ]
          end

          it { is_expected.to eq(normalize_hash_string(expected_output)) }
        end
      end
    end
  end

  context 'when :line_width' do
    subject { instance.clean_lines.last }

    before { instance.log(input) }

    context 'is 80 (default)' do
      it { is_expected.to eq('=' * 80) }
    end

    context 'is 20' do
      let(:line_width) { 20 }

      it { is_expected.to eq('=' * 20) }
    end
  end

  context 'when :key_width' do
    subject { instance.clean_lines.first }

    before { instance.log(input) }

    context 'is 30 (default)' do
      it { is_expected.to eq('rails                         : 4') }
    end

    context 'is 20' do
      let(:key_width) { 20 }

      it { is_expected.to eq('rails               : 4') }
    end
  end

  context 'when :indent' do
    subject { [instance.clean_lines[2], instance.clean_lines[5]] }

    before { instance.log(input) }

    context 'convert hash to nested open struct just so this test works' do
      let(:convert_data_to) { :open_struct }

      context 'is "  " (default)' do
        it do
          is_expected.to include(
            '  some                        : data',
            '    extra_info                : info'
          )
        end
      end

      context 'is "..."' do
        let(:indent) { '...' }

        it do
          is_expected.to include(
            '...some                       : data',
            '......extra_info              : info'
          )
        end
      end
    end
  end

  context 'when :show_array_count' do
    subject { instance.clean_lines }

    before { instance.log(input) }

    let(:show_array_count) { true } # defaults to nil - valid values: [nil, true, false]
    let(:input) { hash_as_open_struct }

    it { is_expected.to include('more_people                   : 2', 'people                        : 4') }
  end

  context 'when :title' do
    subject { instance.clean_lines }

    before { instance.log(input) }

    let(:line_width) { 20 }
    let(:line_equals) { '=' * line_width }
    let(:line_dashes) { '-' * line_width }
    let(:graph) do
      {
        rails: { skip: true },
        complex: { skip: true },
        people: { skip: true }
      }
    end

    context 'when title' do
      let(:title) { 'Main Title' }

      context 'and title_type is' do
        context ':heading' do
          it { is_expected.to contain_exactly(line_equals, title, line_equals, line_equals) }
        end
        context ':subheading' do
          let(:title_type) { :subheading }

          it { is_expected.to contain_exactly(line_dashes, title, line_dashes, line_equals) }
        end
        context ':section' do
          let(:title_type) { :section }

          it { is_expected.to contain_exactly('[ Main Title ]------', line_equals) }
        end
      end
    end

    context 'when no title' do
      it { is_expected.to contain_exactly(line_equals) }
    end
  end

  context 'when graph->(array data) [take, filter, sort, no_data, columns]' do
    subject { instance.clean_lines }

    before { instance.log(input) }

    let(:graph) do
      {
        rails: { skip: true },
        complex: { skip: true },
        people: people
      }
    end

    context 'take' do
      context 'take: 2' do
        let(:people) { { take: 2 } }
        it { is_expected.to have(5).items }
      end

      context 'take: :all' do
        let(:people) { { take: :all } }
        # TODO: FIX
        it { is_expected.to have(7).items }
      end
    end

    context 'columns' do
      subject { instance.clean_lines[0..-2] }
      context 'show specific columns' do
        let(:people) { { columns: %i[active first_name last_name] } }
        it do
          is_expected.to eq([
                              'ACTIVE | FIRST_NAME | LAST_NAME',
                              '-------|------------|----------',
                              'true   | david      | cruwys   ',
                              'true   | joh        | doe      ',
                              'true   | lisa       | lou      ',
                              'false  | amanda     | armor    '
                            ])
        end
      end

      context 'show using custom display_method' do
        context 'when input is open_struct' do
          let(:input) { hash_as_open_struct }
          let(:people) do
            {
              columns: [
                { full_name: { display_method: ->(row) { "#{row.first_name} #{row.last_name}" } } },
                # NOTE: you cannot use display_name and display_method together
                # It would be nice to have display_name: '# of Children'
                { child_count: { display_method: ->(row) { row.children.length } } }
              ]
            }
          end

          it do
            is_expected.to eq([
                                'FULL_NAME    | CHILD_COUNT',
                                '-------------|------------',
                                'david cruwys | 1          ',
                                'joh doe      | 1          ',
                                'lisa lou     | 0          ',
                                'amanda armor | 2          '
                              ])
          end
        end

        context 'when input is custom model' do
          let(:input) { hash_as_model }
          let(:people) do
            {
              columns: [
                { full_name: { display_method: ->(row) { row.full_name } } },
                { child_count: { display_method: ->(row) { row.child_count } } }
              ]
            }
          end

          it do
            is_expected.to eq([
                                'FULL_NAME    | CHILD_COUNT',
                                '-------------|------------',
                                'david cruwys | 1 children ',
                                'joh doe      | 1 children ',
                                'lisa lou     | 0 children ',
                                'amanda armor | 2 children '
                              ])
          end
        end
      end

      context 'show using custom display_name (title)' do
        let(:people) do
          {
            columns: [
              { first_name: { display_name: 'Name' } }
            ]
          }
        end

        it do
          is_expected.to eq([
                              'NAME  ',
                              '------',
                              'david ',
                              'joh   ',
                              'lisa  ',
                              'amanda'
                            ])
        end
      end

      context 'show using child columns' do
        let(:convert_data_to) { :open_struct }
        let(:people) do
          {
            columns: [
              :first_name,
              'children.name',
              'children.age'
            ]
          }
        end
        it do
          is_expected.to eq([
                              'FIRST_NAME | CHILDREN.NAME | CHILDREN.AGE',
                              '-----------|---------------|-------------',
                              'david      | Steven        | 21          ',
                              'joh        | Alison        | 17          ',
                              'lisa       |               |             ',
                              'amanda     | Fiona         | 7           ',
                              '           | Sam           | 2           '
                            ])
        end
      end

      context 'show using display_method for child values' do
        let(:convert_data_to) { :open_struct }
        let(:people) do
          {
            columns: [
              :first_name,
              { children: { display_method: ->(row) { row.children.map { |c| "#{c.name} (#{c.gender[0]})" }.join(', ') } } }
            ]
          }
        end

        it do
          is_expected.to eq([
                              'FIRST_NAME | CHILDREN          ',
                              '-----------|-------------------',
                              'david      | Steven (M)        ',
                              'joh        | Alison (F)        ',
                              'lisa       |                   ',
                              'amanda     | Fiona (F), Sam (M)'
                            ])
        end
      end

      context 'show using deep nested child columns' do
        let(:convert_data_to) { :open_struct }
        let(:people) do
          {
            columns: [
              :first_name,
              'children.name',
              'children.age',
              'children.hobbies.to_s'
            ]
          }
        end

        # { hobbies: { display_method: ->(row) { row.hobbies.join(', ') } } },
        # { first_5_column_names: { width: 150, display_method: ->(row) { row.columns.take(5).map(&:name).join(', ') } } }

        it do
          is_expected.to eq([
                              'FIRST_NAME | CHILDREN.NAME | CHILDREN.AGE | CHILDREN.HOBBIES.TO_S',
                              '-----------|---------------|--------------|----------------------',
                              'david      | Steven        | 21           | football             ',
                              '           |               |              | play station         ',
                              'joh        | Alison        | 17           | basketball           ',
                              '           |               |              | theatre              ',
                              '           |               |              | dance                ',
                              'lisa       |               |              |                      ',
                              'amanda     | Fiona         | 7            | dance                ',
                              '           |               |              | music                ',
                              '           | Sam           | 2            |                      '
                            ])
        end
      end

      context 'show using convert to hash with wide column' do
        let(:people) do
          {
            columns: [
              :first_name,
              { data: { width: 250, display_method: ->(row) { KUtil.data.to_hash(row) } } }
            ]
          }
        end

        it do
          is_expected.to eq([
                              'FIRST_NAME | DATA                                                                                                                                                                                                                                ',
                              '-----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------',
                              'david      | {"first_name"=>"david", "last_name"=>"cruwys", "age"=>45, "active"=>true, "children"=>[{"name"=>"Steven", "gender"=>"Male", "age"=>21, "hobbies"=>["football", "play station"]}]}                                                   ',
                              'joh        | {"first_name"=>"joh", "last_name"=>"doe", "age"=>38, "active"=>true, "children"=>[{"name"=>"Alison", "gender"=>"Female", "age"=>17, "hobbies"=>["basketball", "theatre", "dance"]}]}                                                ',
                              'lisa       | {"first_name"=>"lisa", "last_name"=>"lou", "age"=>23, "active"=>true, "children"=>[]}                                                                                                                                               ',
                              'amanda     | {"first_name"=>"amanda", "last_name"=>"armor", "age"=>29, "active"=>false, "children"=>[{"name"=>"Fiona", "gender"=>"Female", "age"=>7, "hobbies"=>["dance", "music"]}, {"name"=>"Sam", "gender"=>"Male", "age"=>2, "hobbies"=>[]}]}'
                            ])
        end
      end
    end

    context 'filter' do
      context 'when using raw data' do
        let(:convert_data_to) { :open_struct }
        context 'filter: active' do
          let(:people) { { filter: ->(row) { row['active'] } } }
          it { is_expected.to have(6).items }
        end

        context 'filter: inactive' do
          let(:people) { { filter: ->(row) { !row['active'] } } }
          it { is_expected.to have(4).items }
          # context { it_behaves_like(:write_file) }
        end
      end

      context 'when using transformed data' do
        context 'filter: active' do
          let(:people) do
            {
              transform: ->(array) { array.map { |v| KUtil.data.to_open_struct(v) } },
              filter: ->(row) { row.active }
            }
          end
          it { is_expected.to have(6).items }
        end

        context 'filter: inactive' do
          let(:people) do
            {
              transform: ->(array) { array.map { |v| KUtil.data.to_open_struct(v) } },
              filter: ->(row) { !row.active }
            }
          end
          it { is_expected.to have(4).items }
        end
      end
    end

    context 'sort' do
      subject { instance.clean_lines[2..5] }

      context 'sort: active (asc), age(asc)' do
        let(:convert_data_to) { :open_struct }
        let(:people) do
          {
            columns: %i[first_name last_name age active],
            sort: ->(a, b) { [a.active.to_s, a.age] <=> [b.active.to_s, b.age] }
          }
        end

        it do
          is_expected.to eq([
                              'amanda     | armor     | 29  | false ',
                              'lisa       | lou       | 23  | true  ',
                              'joh        | doe       | 38  | true  ',
                              'david      | cruwys    | 45  | true  '
                            ])
        end
      end

      context 'sort: active (asc), age(desc)' do
        let(:convert_data_to) { :open_struct }
        let(:people) do
          {
            columns: %i[first_name last_name age active],
            sort: ->(a, b) { [a.active.to_s, b.age] <=> [b.active.to_s, a.age] }
          }
        end

        it do
          is_expected.to eq([
                              'amanda     | armor     | 29  | false ',
                              'david      | cruwys    | 45  | true  ',
                              'joh        | doe       | 38  | true  ',
                              'lisa       | lou       | 23  | true  '
                            ])
        end
      end

      context 'sort: active (desc), age(asc)' do
        let(:convert_data_to) { :open_struct }
        let(:people) do
          {
            columns: %i[first_name last_name age active],
            sort: ->(a, b) { [b.active.to_s, a.age] <=> [a.active.to_s, b.age] }
          }
        end

        it do
          is_expected.to eq([
                              'lisa       | lou       | 23  | true  ',
                              'joh        | doe       | 38  | true  ',
                              'david      | cruwys    | 45  | true  ',
                              'amanda     | armor     | 29  | false '
                            ])
        end
      end

      context 'sort: active (desc), age(desc)' do
        let(:convert_data_to) { :open_struct }
        let(:people) do
          {
            columns: %i[first_name last_name age active],
            sort: ->(a, b) { [b.active.to_s, b.age] <=> [a.active.to_s, a.age] }
          }
        end

        it do
          is_expected.to eq([
                              'david      | cruwys    | 45  | true  ',
                              'joh        | doe       | 38  | true  ',
                              'lisa       | lou       | 23  | true  ',
                              'amanda     | armor     | 29  | false '
                            ])
        end
      end
    end

    context 'no_data' do
      context 'take: 0' do
        let(:people) { { take: 0 } }
        it { is_expected.to have(2).items }
      end
      context 'take: 0 with heading' do
        let(:people) { { take: 0, heading: 'show people' } }
        it { is_expected.to have(3).items }
      end
      context 'take: 0 with heading' do
        let(:people) { { take: 0, heading: 'show people', skip_empty: true } }
        it { is_expected.to have(1).items }
      end
    end
  end

  context 'when graph->(:heading, :heading_type)' do
    before { instance.log(input) }

    let(:convert_data_to) { :open_struct }
    let(:line_width) { 50 }
    let(:line_equals) { '=' * line_width }
    let(:line_dashes) { '-' * line_width }
    let(:graph) do
      {
        rails: { skip: true },
        complex: graph_complex,
        people: { skip: true }
      }
    end

    context 'for hierarchial structure' do
      context 'with heading_type: :section (default)' do
        subject { instance.clean_lines.first }
        let(:graph_complex) do
          {
            heading: 'Complex Heading (:section)'
          }
        end
        it { is_expected.to eq('[ Complex Heading (:section) ]--------------------') }
      end

      context 'with heading_type: :heading' do
        subject { instance.clean_lines[0..2] }
        let(:graph_complex) do
          {
            heading: 'Complex Heading (:heading)',
            heading_type: :heading
          }
        end
        it { is_expected.to contain_exactly(line_equals, 'Complex Heading (:heading)', line_equals) }
      end

      context 'with heading_type: :subheading' do
        subject { instance.clean_lines[0..2] }
        let(:graph_complex) do
          {
            heading: 'Complex Heading (:subheading)',
            heading_type: :subheading
          }
        end
        it { is_expected.to contain_exactly(line_dashes, 'Complex Heading (:subheading)', line_dashes) }
      end

      context 'headings at multiple nested levels' do
        subject { instance.clean_lines }
        let(:graph_complex) do
          {
            heading: 'Complex Heading (:section)',
            extra: {
              heading: 'Extra',
              heading_type: :section,
              more_people: {
                heading: 'Lots of People'
              }
            },
            other_info: {
              heading: 'Other info',
              heading_type: :subheading
            }
          }
        end
        it do
          is_expected
            .to   include('[ Complex Heading (:section) ]--------------------')
            .and  include('[ Extra ]-----------------------------------------')
            .and  include('[ Lots of People ]--------------------------------')
            .and  include('Other info')
        end
      end
    end
  end

  context 'when :convert_data_to' do
    subject { instance.clean_content }

    before { instance.log(input) }

    context 'is :raw (default)' do
      it do
        is_expected
          .to   include('rails                         : 4')
          .and  include('{"some"=>"data", "some_more"=>"data", "extra"=>{"extra_info"=>"info", "more_info"=>"and more", "names"=>["david", "was", "here"], "ages"=>[23, 53, 64], "more_people"=>[{"age"=>45, "first_name"=>"bob", "last_name"=>"jane"}, {"age"=>25, "first_name"=>"sam", "last_name"=>"sugar"}]}, "other_info"=>"other"}')
      end
    end

    context 'is :raw (symbolized hash)' do
      context { it_behaves_like(:write_file) }

      it do
        is_expected
          .to   include('rails                         : 4')
          .and  include('{"some"=>"data", "some_more"=>"data", "extra"=>{"extra_info"=>"info", "more_info"=>"and more", "names"=>["david", "was", "here"], "ages"=>[23, 53, 64], "more_people"=>[{"age"=>45, "first_name"=>"bob", "last_name"=>"jane"}, {"age"=>25, "first_name"=>"sam", "last_name"=>"sugar"}]}, "other_info"=>"other"}')
      end
    end

    context 'is :open_struct' do
      let(:convert_data_to) { :open_struct }

      it do
        is_expected
          .to   include('rails                         : 4')
          .and  include('    ages                      : 23, 53, 64')
          .and  include('    extra_info                : info')
          .and  include('45  | bob        | jane     ')
          .and  include('david      | cruwys    | 45  | true  ')
      end
    end
  end

  context 'when graph' do
    subject { instance.clean_content }

    before { instance.log(input) }

    context 'when convert_data_to: :open_struct' do
      let(:convert_data_to) { :open_struct }

      context 'level 1 node is skipped' do
        let(:graph) do
          {
            rails: {
              skip: true
            }
          }
        end

        it do
          is_expected.not_to include('rails                         : 4')

          is_expected
            .to   include('AGE | FIRST_NAME | LAST_NAME')
            .and  include('FIRST_NAME | LAST_NAME')
            .and  include('    ages                      : 23, 53, 64')
        end
      end

      context 'level 1 and 2 nodes is skipped' do
        let(:graph) do
          {
            complex: {
              extra: {
                skip: true
              }
            },
            people: {
              skip: true
            }
          }
        end

        it do
          is_expected.not_to include('  ages                        : 23, 53, 64')
          is_expected.not_to include('AGE | FIRST_NAME | LAST_NAME')
          is_expected.not_to include('FIRST_NAME | LAST_NAME')

          is_expected
            .to   include('rails                         : 4')
            .and  include('complex')
            .and  include('  some_more                   : data')
            .and  include('  other_info                  : other')
        end
      end
    end

    context 'when transforming a node' do
      let(:graph) do
        {
          rails: { skip: true },
          complex: complex,
          people: { skip: true }
        }
      end

      context 'without transformer' do
        let(:complex) { nil }
        it do
          is_expected.to include('{"some"=>"data", "some_more"=>"data", "extra"=>{"extra_info"=>"info", "more_info"=>"and more", "names"=>["david", "was", "here"], "ages"=>[23, 53, 64], "more_people"=>[{"age"=>45, "first_name"=>"bob", "last_name"=>"jane"}, {"age"=>25, "first_name"=>"sam", "last_name"=>"sugar"}]}, "other_info"=>"other"}')
        end
      end
      context 'with hash transformer' do
        let(:complex) do
          {
            transform: ->(v) { KUtil.data.to_open_struct(v) }
          }
        end

        it do
          is_expected
            .to   include('complex')
            .and  include('    ages                      : 23, 53, 64')
            .and  include('    extra_info                : info')
            .and  include('45  | bob        | jane     ')
            .and  include('  other_info                  : other')
        end

        context 'and value transformer' do
          # let(:indent) { '**'}
          let(:complex) do
            {
              transform: ->(v) { KUtil.data.to_open_struct(v) },
              extra: {
                more_people: { skip: true }
              },
              other_info: {
                transform: ->(v) { "[---#{v}---]" }
              }
            }
          end

          it do
            is_expected
              .to   include('complex')
              .and  include('    ages                      : 23, 53, 64')
              .and  include('    extra_info                : info')
              .and  include('  other_info                  : [---other---]')
          end
        end
      end
    end
  end

  describe 'complex->*.rb - custom dry classes' do
    let(:model) { hash_as_model }

    it do
      expect(model.rails).to eq(4)
      expect(model.complex).not_to be_nil
      expect(model.complex.some).to eq('data')
      expect(model.complex.some_more).to eq('data')
      expect(model.complex.extra.more_info).to eq('and more')
      expect(model.complex.extra.names).to include('david', 'was', 'here')
      expect(model.complex.extra.ages).to include(23, 53, 64)
      expect(model.complex.extra.more_people.first).to have_attributes(age: 45, first_name: 'bob', last_name: 'jane')

      expect(model.people.first).to have_attributes(first_name: 'david', last_name: 'cruwys', age: 45, active: true)
      expect(model.people.first.children.first).to have_attributes(name: 'Steven', gender: 'Male', age: 21, hobbies: include('football', 'play station'))

      # puts model.rails
      # puts model.complex.some
      # puts model.complex.some_more
      # puts model.complex.extra.extra_info
      # puts model.complex.extra.more_info
      # puts model.complex.extra.names.join(', ')
      # puts model.complex.extra.ages.join(' + ')
      # puts model.complex.extra.more_people.map { |p| "#{p.first_name} #{p.last_name} (#{p.age})" }.join(" | ")
      # people_children = model.people.flat_map do |p|
      #   result = ["#{p.first_name} #{p.last_name} (#{p.age}) #{p.active ? '' : "INACTIVE"}"]
      #   result = result + p.children.map { |c| "#{c.name} (#{c.gender}: #{c.age}) #{c.hobbies.join(',')}".strip }
      #   result
      # end
      # puts people_children
    end
  end

  # rubocop:disable Metrics/AbcSize
  def vs(log_structure, sleep_for: 2)
    return if log_structure.nil?

    if !log_structure.output_as.include?(:file) || log_structure.output_file.nil?

      KLog.logger.error 'Following options are needed to open file in VSCode'
      KLog.logger.kv 'output_as', log_structure.output_as
      KLog.logger.kv 'output_file', log_structure.output_file

      return
    end

    file      = log_structure.output_file
    filename  = File.basename(file)
    path      = File.dirname(file)

    build_command = "cd #{path} && code #{filename}"

    system(build_command)

    sleep sleep_for
  end
  # rubocop:enable Metrics/AbcSize
end
