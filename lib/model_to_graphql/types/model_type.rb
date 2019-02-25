# frozen_string_literal: true

module ModelToGraphql
  module Types
    class ModelType < GraphQL::Schema::Object
      class << self
        attr_accessor :model_class

        def add_model_class(model_class)
          self.model_class = model_class
        end

        def [](model)
          Class.new(ModelToGraphql::Types::ModelType) do
            add_model_class model
            description "Model Type Resolver"
            graphql_name "#{model.name}GraphqlTypeResolver"
            field :name, String, null: true
          end
        end

        def inspect
          "#<#{graphql_name}>"
        end
      end
    end
  end
end
