
# frozen_string_literal: true

module ModelToGraphql
  module Objects
    class RawJson < GraphQL::Schema::Scalar
      description "A valid JSON"
  
      def self.coerce_input(input_value, context)
        # JSON.parse(input_value)
        input_value
      end
  
      def self.coerce_result(ruby_value = {}, context)
        ruby_value
      end
    end
  end
end
