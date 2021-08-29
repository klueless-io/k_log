# frozen_string_literal: true

module ComplexStructure
  class People < Dry::Struct
    attribute :age        , Types::Strict::Integer
    attribute :first_name , Types::Strict::String
    attribute :last_name  , Types::Strict::String
    attribute :active     , Types::Strict::Bool
    attribute :children   , Types::Strict::Array.of(ComplexStructure::Children)

    def full_name
      "@#{first_name} @#{last_name}"
    end
  end
end
