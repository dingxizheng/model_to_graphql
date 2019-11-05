# frozen_string_literal: true

module ModelToGraphql
  module Types
    class ModelType < GraphQL::Schema::Object

      class << self
        attr_accessor :model_class_name

        def add_model_class(model_class)
          self.model_class_name = model_class.name
        end

        def model_class
          self.model_class_name.constantize
        end

        def [](model)
          const_name = "#{model_name(model)}GraphqlTypeResolver"
          return self.const_get(const_name) if self.const_defined?(const_name)

          klass = Class.new(ModelToGraphql::Types::ModelType) do
                    add_model_class model
                    description     "Model Type Resolver"
                    graphql_name    const_name
                    field           :name, String, null: true # Only used for defining the schema
                  end
          self.const_set(const_name, klass)
        end

        def self.remove_all_constants
          self.constants.each do |c|
            self.send(:remove_const, c)
          end
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
