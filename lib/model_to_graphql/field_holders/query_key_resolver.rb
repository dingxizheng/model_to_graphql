# frozen_string_literal: true

module ModelToGraphql
  module FieldHolders
    class QueryKeyResolver < BaseResolver
      include ModelToGraphql::ObjectCache

      class << self
        attr_accessor :model_class_name

        def add_model_class(model_class)
          self.model_class_name = model_class.name
        end

        def model_class
          self.model_class_name.constantize
        end

        def [](model)
          graphl_obj_name = "#{model.name}GraphqlQueryKeyResolver"
          get_object(graphl_obj_name) || cache(graphl_obj_name,
            Class.new(ModelToGraphql::FieldHolders::QueryKeyResolver) do
              add_model_class model
              graphql_name    graphl_obj_name
              argument        :id, String, required: false
              type            String, null: true
            end
          )
        end
      end
    end
  end
end
