# frozen_string_literal: true

require_relative "../object_cache.rb"
module ModelToGraphql
  module Types
    class UnionModelType < GraphQL::Schema::Object
      include ModelToGraphql::ObjectCache

      class << self
        attr_accessor :context, :relation, :resolved

        def [](relation, context)
          type_name = "Possible#{relation.name.capitalize}Type"
          graphql_obj_name = "#{type_name}GraphqlUnionTypeResolver"
          # Get it from cache or create a new one
          get_object(graphql_obj_name) || cache(graphql_obj_name,
            Class.new(ModelToGraphql::Types::UnionModelType) do
              self.context  = context
              self.relation = relation
              description     "Union Model Type Resolver"
              graphql_name    graphql_obj_name
              field           :name, String, null: true # Only used for defining the schema
            end
          )
        end

        def resolve_possible_types
          return resolved if resolved
          graphql_types = context.parsed_models.select do |m|
            m.model.relations.any? { |_, field| field.options[:as] == relation.name && field.klass == relation.inverse_class }
          end.map { |m| m.type }
          ModelToGraphql.logger.debug "ModelToGQL | Resolved the possible types for relation #{relation}: [#{graphql_types}]"
          type_name = "Possible#{relation.name.capitalize}Type"
          engine_context = context
          self.resolved = Class.new(GraphQL::Schema::Union) do
                            @@context = engine_context
                            graphql_name(type_name)
                            possible_types(*graphql_types)
                            def self.resolve_type(obj, _ctx)
                              @@context.find_meta(obj.class).type
                            rescue => _
                              fail "Couldn't find the return type of object #{obj} when its class it's #{obj.class}"
                            end
                          end
        end

        def inspect
          "#<#{graphql_name}>"
        end
      end
    end
  end
end
