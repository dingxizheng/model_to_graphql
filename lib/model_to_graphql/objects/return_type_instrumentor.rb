# frozen_string_literal: true

require_relative "../types/model_type.rb"

module ModelToGraphql
  module Objects
    class ReturnTypeInstrumentor

      attr_accessor :return_type_resolver

      def initialize(resolver)
        self.return_type_resolver = resolver
      end

      def instrument(type, field)
        field_return_type = field.metadata[:type_class].type
        if field_return_type.is_a?(Class) && field_return_type < ModelToGraphql::Types::ModelType
          return_type = return_type_resolver.call(field_return_type.model_class)
          field.redefine do
            type(return_type)
          end
        else
          field
        end
      end
    end
  end
end