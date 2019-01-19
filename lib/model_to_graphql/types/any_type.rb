# frozen_string_literal: true

module ModelToGraphql
  module Types
    class AnyType < GraphQL::Schema::Scalar
      description "ANY TYPE"

      def self.coerce_input(input_value, context)
        input_value
      end

      def self.coerce_result(ruby_value = {}, context)
        ruby_value
      end
    end
  end
end
