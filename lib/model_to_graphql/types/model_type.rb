# frozen_string_literal: true

module ModelToGraphql
  module Types
    class ModelType < GraphQL::Schema::Object

      class << self
        def [](model)
          ModelToGraphql::Objects::Type[model]
        end
      end
    end
  end
end
