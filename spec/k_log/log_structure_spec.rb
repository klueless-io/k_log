# frozen_string_literal: true

require 'spec_helper'
require 'k_log/examples'
require 'json'

RSpec.describe KLog::LogStructure do
  subject { instance.log(data) }

  let(:instance) { described_class.new(**opts) }
  # let(:data) { File.rea }
  let(:file) { 'spec/data/db_schema.json' }
  let(:json) { File.read(file) }
  let(:data) { JSON.parse(json) }
  let(:take_limit) { :all }
  let(:opts) { {} }
  let(:base_opts) do
    {
      formatter: {
        tables: {
          take: take_limit
        },
        foreign_keys: {
          take: take_limit
        },
        all_indexes: {
          take: take_limit
        },
        keys: {
          take: take_limit
        },
        people: {
          take: take_limit
        }
      }
    }
  end
  # NOTE: remove take: from display and it to filter

  describe 'examples' do
    context 'show all data' do
      let(:opts) { {} }

      it '#log_structure' do
        subject
      end
    end

    context 'when tabular prints are limited to taking zero records' do
      let(:opts) { base_opts }
      let(:take_limit) { 0 }

      it '#log_structure' do
        subject
      end

      context 'and with main heading' do
        let(:opts) { base_opts.merge(heading: 'This is the main heading') }

        it '#log_structure' do
          subject
        end

        context 'using subheading format' do
          let(:opts) { base_opts.merge(heading: 'This is the main heading', heading_type: :subheading) }

          it '#log_structure' do
            subject
          end
        end

        context 'and with altered line length' do
          let(:opts) { base_opts.merge(heading: 'This is the main heading', line_width: 30) }

          it '#log_structure' do
            subject
          end
        end
      end
    end

    context 'when taking 2 record in tabular prints' do
      let(:opts) { base_opts }
      let(:take_limit) { 2 }

      it '#log_structure' do
        subject
      end
    end

    context 'when adding titles with different styles to tabular printouts' do
      let(:take_limit) { 0 }
      let(:opts) do
        {
          formatter: {
            tables: {
              heading: 'title for tables',
              heading_type: :heading,
              take: take_limit
            },
            foreign_keys: {
              heading: 'title for foreign keys',
              heading_type: :subheading,
              take: take_limit
            },
            all_indexes: {
              heading: 'title for indexes',
              heading_type: :section_heading,
              take: take_limit
            },
            keys: {
              heading: 'title for keys',
              take: take_limit
            },
            people: {
              heading: 'title for people',
              take: take_limit
            }
          }
        }
      end

      it '#log_structure' do
        subject
      end
    end

    context 'when using custom column formatters in tabular printouts' do
      let(:take_limit) { 0 }
      let(:opts) do
        {
          heading: 'PostgreSQL Database Schema for Rails Application',
          line_width: 180,
          formatter: {
            tables: {
              heading: 'Database Tables',
              take: :all,
              array_columns: [
                :name,
                :force,
                :primary_key,
                :id,
                { index_count: { display_method: ->(row) { row.indexes.length } } },
                { column_count: { display_method: ->(row) { row.columns.length } } },
                { first_5_column_names: { width: 150, display_method: ->(row) { row.columns.take(5).map(&:name).join(', ') } } }
              ]
            },
            foreign_keys: {
              heading: 'PostgreSQL - All foreign leys',
              take: 5
            },
            all_indexes: {
              heading: 'PostgreSQL - All indexes',
              take: 5,
              array_columns: [
                :name,
                { fields: { width: 150, display_method: ->(row) { row.fields.join(', ') } } },
                :using,
                { order: { width: 100, display_method: ->(row) { row.order.to_h } } },
                { where: { display_method: ->(row) { row[:where] } } },
                { unique: { display_method: ->(row) { row[:unique] } } }
              ]
            },
            keys: {
              heading: 'Title for Keys',
              take: 20,
              array_columns: [
                :type,
                :category,
                :key,
                { keys: { width: 100, display_method: ->(row) { row.keys.join(', ') } } }
              ]
            },
            people: {
              heading: 'List of people',
              array_columns: [
                :first_name,
                :last_name,
                { full_name: { width: 100, display_method: ->(row) { "#{row.first_name} #{row.last_name}" } } }
              ]
            }
          }
        }
      end

      it '#log_structure' do
        subject
      end
    end

    context 'when ignoring sections' do
      let(:take_limit) { 10 }
      let(:opts) do
        {
          formatter: {
            _root: { ignore: true },
            tables: {
              take: take_limit
            },
            foreign_keys: { ignore: true },
            all_indexes: { ignore: true },
            keys: { ignore: true },
            people: { ignore: true }
          }
        }
      end

      it '#log_structure' do
        subject
      end
    end
  end
end
