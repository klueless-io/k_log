# frozen_string_literal: true

module ComplexStructure
  class MorePeople < Dry::Struct
    attribute :age        , Types::Strict::Integer
    attribute :first_name , Types::Strict::String
    attribute :last_name  , Types::Strict::String

    def full_name
      "@#{first_name} @#{last_name}"
    end
  end
end
