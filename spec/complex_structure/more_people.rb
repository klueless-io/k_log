# frozen_string_literal: true

module ComplexStructure
  class MorePeople < Dry::Struct
    attribute :age        , Types::Strict::Integer
    attribute :first_name , Types::Strict::String
    attribute :last_name  , Types::Strict::String
  end
end
