# frozen_string_literal: true

require_relative "../types/model_type.rb"
require_relative "../field_holders/base_resolver.rb"
require_relative "../object_cache.rb"
require_relative "../types/paged_result_type.rb"

module ModelToGraphql
  module FieldHolders
    class QueryResolver < BaseResolver
      include ModelToGraphql::ObjectCache

      class << self
        attr_accessor :model_class_name

        def add_model_class(model_class)
          self.model_class_name = model_class.name
        end

        def model_class
          self.model_class_name.safe_constantize
        end

        def [](model)
          graphql_obj_name = "#{model.name}GraphqlQueryRecordResolver"
          get_object(graphql_obj_name) || cache(graphql_obj_name,
            Class.new(ModelToGraphql::FieldHolders::QueryResolver) do
              add_model_class model
              graphql_name    graphql_obj_name
              argument        :id, String, required: false
              type            String, null: true
            end
          )
        end
      end
    end
  end
end
