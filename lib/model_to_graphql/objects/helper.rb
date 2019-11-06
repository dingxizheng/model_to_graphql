# frozen_string_literal: true

module ModelToGraphql
  module Objects
    class Helper
      class << self
        def make_model_definition(model_name)
          model = model_name.constantize
          model_def = find_model_def(model)&.constantize || create_model_def(model)
          model_def.scan_relations
          model_def
        end

        def make_return_type(model_name)
          model      = model_name.constantize
          model_def  = ModelToGraphql::Objects::ModelDefinition[model_name]
          fields     = model_def.merged_fields
          raw_fields = model_def.raw_fields || []
          ModelToGraphql::Generators::TypeGenerator.build(return_type_name(model), fields, raw_fields)
        end

        def make_query_type(model_name)
          model          = model_name.constantize
          model_def      = ModelToGraphql::Objects::ModelDefinition[model_name]
          fields         = model_def.merged_fields
          custom_filters = model_def.filters || []
          ModelToGraphql::Generators::QueryTypeGenerator.build(query_type_name(model), fields, custom_filters)
        end

        def make_query_resolver(model_name)
          model       = model_name.constantize
          return_type = ModelToGraphql::Objects::Type[model_name]
          query_type  = ModelToGraphql::Objects::QueryType[model_name]
          sort_enum   = ModelToGraphql::Objects::SortKey[model_name]
          ModelToGraphql::Generators::ModelQueryGenerator.build(model, return_type, query_type, sort_enum)
        end

        def make_record_resolver(model_name)
          model       = model_name.constantize
          return_type = ModelToGraphql::Objects::Type[model_name]
          ModelToGraphql::Generators::SingleRecordQueryGenerator.build(model, return_type)
        end

        def make_sort_key_enum(model_name)
          model      = model_name.constantize
          model_def  = ModelToGraphql::Objects::ModelDefinition[model_name]
          fields     = model_def.merged_fields
          ModelToGraphql::Generators::SortKeyEnumGenerator.build(sort_key_enum_name(model), fields)
        end

        def make_query_key_enum(model_name)
          model = model_name.constantize
          query = ModelToGraphql::Objects::QueryType[model_name]
          query_key_name = query_key_enum_name(model)
          Class.new(GraphQL::Schema::Enum) do
            graphql_name(query_key_name)
            query.arguments.keys.each do |name, _|
              value(name, "Query key #{name}")
            end
          end
        end

        private
          def find_model_def(model)
            @def_names ||= ModelToGraphql::Definitions::ModelDefinition.definitions.map(&:name).compact
            @def_names.select do |definition_name|
              definition = definition_name.constantize
              model == definition.model
            end&.first
          end

          def create_model_def(model)
            Class.new(ModelToGraphql::Definitions::ModelDefinition) do
              define_for_model model
            end
          end

          def model_name(model)
            model.name.delete("::")
          end

          def return_type_name(model)
            "#{model_name(model)}Type"
          end

          def query_type_name(model)
            "#{model_name(model)}Query"
          end

          def query_key_enum_name(model)
            "#{model_name(model)}QueryKey"
          end

          def sort_key_enum_name(model)
            "#{model_name(model)}SortKey"
          end
      end
    end
  end
end
