# frozen_string_literal: true

# require_relative ''

module ComplexStructure
  class Complex < Dry::Struct
    attribute :some                , Types::Strict::String
    attribute :some_more           , Types::Strict::String
    attribute :extra               , ComplexStructure::Extra
    attribute :other_info          , Types::Strict::String
  end
end
