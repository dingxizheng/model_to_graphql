# frozen_string_literal: true

require_relative "../types/model_type.rb"
require_relative "../types/union_model_type.rb"
require_relative "../field_holders/query_resolver.rb"
require_relative "../field_holders/single_resolver.rb"
require_relative "../field_holders/base_resolver.rb"
require_relative "../field_holders/query_key_resolver.rb"

module ModelToGraphql
  module Objects
    class ReturnTypeInstrumentor
      include ModelToGraphql::FieldHolders
      include ModelToGraphql::Types

      attr_accessor :meta_type_resolver

      def initialize(resolver)
        self.meta_type_resolver = resolver
      end

      def instrument(type, field)
        field_return_type   = field.metadata[:type_class].type
        resolver_class_type = field.metadata[:resolver] || String

        # Return original field is type or resolver is not an placeholder class
        actual_return_type    = nil
        actual_resolver_class = nil

        if field_return_type.is_a?(Class) && field_return_type < ModelType
          ModelToGraphql.logger.debug "ModelToGQL | Resolving ModelType[#{field_return_type.model_class}] ..."
          meta_type = meta_type_resolver.call(field_return_type.model_class)
          actual_return_type = meta_type.type
          ModelToGraphql.logger.debug "ModelToGQL | ModelType[#{field_return_type.model_class}] resolved to #{actual_return_type.graphql_name}"
        end

        if field_return_type.is_a?(Class) && field_return_type < UnionModelType
          ModelToGraphql.logger.debug "ModelToGQL | Resolving [UnionModelType[#{field_return_type}]] ..."
          actual_return_type = field_return_type.resolve_possible_types
        end

        if field_return_type.is_a?(GraphQL::Schema::List)
          current_type = field_return_type
          while current_type.respond_to? :of_type do
            current_type = current_type.of_type
          end
          if current_type.is_a?(Class) && current_type < ModelType
            ModelToGraphql.logger.debug "ModelToGQL | Resolving [ModelType[#{current_type.model_class}]] ..."
            meta_type = meta_type_resolver.call(current_type.model_class)
            actual_return_type = GraphQL::Schema::List.new(GraphQL::Schema::NonNull.new(meta_type.type))
            ModelToGraphql.logger.debug "ModelToGQL | [ModelType[#{current_type.model_class}]] resolved to [#{meta_type.type}]"
          end

          if current_type.is_a?(Class) && current_type < UnionModelType
            ModelToGraphql.logger.debug "ModelToGQL | Resolving [UnionModelType[#{current_type}]] ..."
            actual_return_type = current_type.resolve_possible_types
          end
        end

        if resolver_class_type < SingleResolver
          ModelToGraphql.logger.debug "ModelToGQL | Resolving SingleResolver[#{resolver_class_type.model_class}] ..."
          meta_type = meta_type_resolver.call(resolver_class_type.model_class)
          actual_resolver_class = meta_type.single_resolver
        end

        if resolver_class_type < QueryResolver
          ModelToGraphql.logger.debug "ModelToGQL | Resolving QueryResolver[#{resolver_class_type.model_class}] ..."
          meta_type = meta_type_resolver.call(resolver_class_type.model_class)
          if resolver_class_type.resolver_options[:relation]
            cloned_resolver = meta_type.model_resolver.clone
            cloned_resolver.set_relation(resolver_class_type.resolver_options[:relation])
            actual_resolver_class = cloned_resolver
          else
            actual_resolver_class = meta_type.model_resolver
          end
        end

        if resolver_class_type < QueryKeyResolver
          ModelToGraphql.logger.debug "ModelToGQL | Resolving QueryKeyResolver[#{resolver_class_type.model_class}] ..."
          meta_type = meta_type_resolver.call(resolver_class_type.model_class)
          actual_return_type    = GraphQL::Schema::List.new(GraphQL::Schema::NonNull.new(meta_type.query_keys))
          actual_resolver_class = Class.new(GraphQL::Schema::Resolver) do
            @@meta_type = meta_type
            type(actual_return_type, null: false)
            def resolve
              @@meta_type.query_keys.map { |f| f.values.keys }
            end
          end
        end

        if actual_return_type
          field.redefine do
            ModelToGraphql.logger.debug "ModelToGQL | Redefine field #{field}, type: #{actual_return_type.respond_to?(:graphql_name) ? actual_return_type.graphql_name : actual_return_type.inspect}"
            type(actual_return_type)
          end
        elsif actual_resolver_class
          GraphQL::Schema::Field.from_options(field.name, resolver: actual_resolver_class).to_graphql.tap do |d|
            d.metadata[:guard] = field.metadata[:guard]
          end
        else
          field
        end
      end
    end
  end
end
