# frozen_string_literal: true

require_relative "../object_cache.rb"
module ModelToGraphql
  module Types
    class ModelType < GraphQL::Schema::Object
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
          graphql_obj_name = "#{model_name(model)}GraphqlTypeResolver"
          # Get it from cache or create a new one
          get_object(graphql_obj_name) || cache(graphql_obj_name,
            Class.new(ModelToGraphql::Types::ModelType) do
              add_model_class model
              description     "Model Type Resolver"
              graphql_name    graphql_obj_name
              field           :name, String, null: true # Only used for defining the schema
            end
          )
        end

        def inspect
          "#<#{graphql_name}>"
        end

        def model_name(model)
          model.name.delete("::")
        end
      end
    end
  end
end
