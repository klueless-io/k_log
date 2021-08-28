# frozen_string_literal: true

module ComplexStructure
  class Extra < Dry::Struct
    attribute :extra_info         , Types::Strict::String
    attribute :more_info          , Types::Strict::String
    attribute :names              , Types::Strict::Array.of(Types::Coercible::String)
    attribute :ages               , Types::Strict::Array.of(Types::Coercible::Integer)
    attribute :more_people        , Types::Strict::Array.of(ComplexStructure::MorePeople)
  end
end
