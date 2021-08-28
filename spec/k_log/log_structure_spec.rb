# frozen_string_literal: true

# use this to debug any single test by rendering to file name, add [, true] to open in vscode
# fcontext { it_behaves_like(:write_file) }

require 'spec_helper'
require 'k_log/examples'
require 'json'

# { first_5_column_names: { width: 150, display_method: ->(row) { row.columns.take(5).map(&:name).join(', ') } } }
# Printing NON open_struct objects and having access to custom methods
# Transform array items (instead of full transform), is this needed
# Handle data namespace/option namespace conflicts
# Can array be done in details format?
# Improve colorization

RSpec.describe KLog::LogStructure do
  subject { instance.log(data) }

  let(:instance) { described_class.new(**opts) }
  # let(:data) { File.rea }
  let(:input_folder) { 'spec/data' }
  let(:input_filename) { 'complex_structure.json' }
  let(:input_file) { File.join(input_folder, input_filename) }
  let(:json) { File.read(input_file) }
  let(:data) { JSON.parse(json) }

  let(:output_folder) { '/Users/davidcruwys/dev/kgems/k_log/spec/k_log' }
  let(:output_filename) { 'a1.txt' }
  let(:output_file) { File.join(output_folder, output_filename) }

  let(:convert_data_to) { nil } # defaults to :raw     - valid values [:raw, :open_struct]
  # let(:output_as) { :file }           # defaults to :console - valid values [:console, :file, :none]
  let(:output_as) { nil }             # defaults to :console - valid values [:console, :file, :none]
  let(:line_width) { nil }            # defaults to 80
  let(:indent) { nil }                # defaults to '  '
  let(:title) { nil }                 # defaults to nil, is displayed when not nil
  let(:title_type) { nil }            # defaults to :heading - valid values [:heading, :subheading, :section]
  let(:graph) { nil }
  let(:opts) do
    {
      output_as: output_as,
      output_file: output_file,
      convert_data_to: convert_data_to,
      line_width: line_width,
      indent: indent,
      title: title,
      title_type: title_type,
      graph: graph
    }
  end

  shared_context :temp_dir do
    include_context :use_temp_folder

    let(:output_folder) { @temp_folder }
  end

  shared_examples :write_file do |vscode_open = false|
    let(:output_folder) { '/Users/davidcruwys/dev/kgems/k_log/spec/k_log' }

    it { vscode_open ? vs(instance) : instance }
  end

  context 'when :line_width' do
    subject { instance.clean_lines.last }

    before { instance.log(data) }

    context 'is 80 (default)' do
      it { is_expected.to eq('=' * 80) }
    end

    context 'is 20' do
      let(:line_width) { 20 }

      it { is_expected.to eq('=' * 20) }
    end
  end

  context 'when :indent' do
    subject { [instance.clean_lines[2], instance.clean_lines[5]] }

    before { instance.log(data) }

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

  context 'when :title' do
    subject { instance.clean_lines }

    before { instance.log(data) }

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

    before { instance.log(data) }
    let(:convert_data_to) { :open_struct }

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
        let(:people) do
          {
            columns: [
              { full_name: { display_method: ->(row) { "#{row.first_name} #{row.last_name}" } } },
              # NOTE: you cannot use display_name and display_method together
              # It would be nice to have display_name: '# of Children'
              { child_count: { display_method: ->(row) { row['children'].length } } }
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
                              'FIRST_NAME | DATA                                                                                                                                                                                                                   ',
                              '-----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------',
                              'david      | {:first_name=>"david", :last_name=>"cruwys", :age=>45, :active=>true, :children=>[{:name=>"Steven", :gender=>"Male", :age=>21, :hobbies=>["football", "play station"]}]}                                               ',
                              'joh        | {:first_name=>"joh", :last_name=>"doe", :age=>38, :active=>true, :children=>[{:name=>"Alison", :gender=>"Female", :age=>17, :hobbies=>["basketball", "theatre", "dance"]}]}                                            ',
                              'lisa       | {:first_name=>"lisa", :last_name=>"lou", :age=>23, :active=>true, :children=>[]}                                                                                                                                       ',
                              'amanda     | {:first_name=>"amanda", :last_name=>"armor", :age=>29, :active=>false, :children=>[{:name=>"Fiona", :gender=>"Female", :age=>7, :hobbies=>["dance", "music"]}, {:name=>"Sam", :gender=>"Male", :age=>2, :hobbies=>[]}]}'
                            ])
        end
      end
    end

    context 'filter' do
      context 'when using raw data' do
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
    before { instance.log(data) }

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
        context { it_behaves_like(:write_file) }
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

    before { instance.log(data) }

    context 'is :raw (default)' do
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

    before { instance.log(data) }

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
    require 'complex_structure/root'

    let(:symbolized) { KUtil.data.deep_symbolize_keys(data) }
    let(:model) { ComplexStructure::Root.new(symbolized) }

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

  def vs(log_structure, sleep_for: 2)
    return if log_structure.nil?

    if log_structure.output_file.nil?
      puts 'Following options are needed to open file in VSCode'
      puts 'output_as: :file'
      puts 'output_file: output_file'

      return
    end

    file      = log_structure.output_file
    filename  = File.basename(file)
    path      = File.dirname(file)

    build_command = "cd #{path} && code #{filename}"

    system(build_command)

    sleep sleep_for
  end
end
