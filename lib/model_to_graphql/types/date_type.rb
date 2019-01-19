# frozen_string_literal: true

module ModelToGraphql
  module Types
    class DateType < GraphQL::Schema::Scalar
      description "An ISO date"

      # @param value [Date]
      # @return [String]
      def self.coerce_input(str_value, _ctx)
        Date.iso8601(str_value)
      rescue ArgumentError
        # Invalid input
        nil
      end

      # @param str_value [String]
      # @return [Date]
      def self.coerce_result(value, _ctx)
        value.iso8601
      end
    end
  end
end
