# frozen_string_literal: true

module ComplexStructure
  class Children < Dry::Struct
    attribute :name       , Types::Strict::String
    attribute :age        , Types::Strict::Integer
    attribute :gender     , Types::Strict::String
    attribute :hobbies    , Types::Strict::Array.of(Types::Coercible::String)
  end
end
