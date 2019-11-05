# frozen_string_literal: true

module ModelToGraphql
  class ReturnTypeInstrumentor

    def instrument(type, field)
      field_return_type = field.metadata[:type_class].type
      # Return original field is type or resolver is not an placeholder class
      actual_return_type = nil

      if field_return_type.is_a?(Class) && field_return_type < ModelToGraphql::Types::ModelType
        ModelToGraphql.logger.debug "ModelToGQL | Resolving ModelType[#{field_return_type.model_class}] ..."
        actual_return_type = ModelToGraphql::Objects::Type[field_return_type.model_class]
        ModelToGraphql.logger.debug "ModelToGQL | ModelType[#{field_return_type.model_class}] resolved to #{actual_return_type.graphql_name}"
      end
      # if field_return_type.is_a?(Class) && field_return_type < UnionModelType
      #   ModelToGraphql.logger.debug "ModelToGQL | Resolving [UnionModelType[#{field_return_type}]] ..."
      #   actual_return_type = field_return_type.resolve_possible_types
      # end
      if actual_return_type
        field.redefine do
          ModelToGraphql.logger.debug "ModelToGQL | Redefine field #{field}, type: #{actual_return_type.respond_to?(:graphql_name) ? actual_return_type.graphql_name : actual_return_type.inspect}"
          type(actual_return_type)
        end
      else
        field
      end
    end
  end
end