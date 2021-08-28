# frozen_string_literal: true

require_relative 'children'
require_relative 'people'
require_relative 'more_people'
require_relative 'extra'
require_relative 'complex'

module ComplexStructure
  class Root < Dry::Struct
    attribute :rails                , Types::Strict::Integer
    attribute :complex              , ComplexStructure::Complex
    attribute :people               , Types::Strict::Array.of(ComplexStructure::People)
  end
end
