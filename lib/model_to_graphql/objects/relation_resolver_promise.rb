# frozen_string_literal: true

require "promise.rb"
require_relative "../generators/belongs_to_relation_resolver_generator.rb"
require_relative "../generators/embeds_one_relation_resolver.rb"
require_relative "../generators/embeds_many_relation_resolver.rb"
require_relative "../generators/has_one_relation_resolver_generator.rb"

module ModelToGraphql
  module Objects
    class RelationResolverPromise < Promise
      include ModelToGraphql::Generators

      attr_accessor :relation, :context

      def self.of(relation, context)
        promise = new
        promise.relation = relation
        promise.context  = context
        promise
      end

      def resolve
        result =  case relation
                  when Mongoid::Association::Referenced::BelongsTo
                    BelongsToRelationResolverGenerator.to_relation_resolver(relation, resolve_belongs_to_type)
                  when Mongoid::Association::Embedded::EmbedsOne
                    EmbedsOneRelationResolverGenerator.to_relation_resolver(relation, relation.klass.graphql_meta.type)
                  when Mongoid::Association::Embedded::EmbedsMany
                    EmbedsManyRelationResolverGenerator.to_relation_resolver(relation, relation.klass.graphql_meta.type)
                  when Mongoid::Association::Referenced::HasOne
                    HasOneRelationResolverGenerator.to_relation_resolver(relation, relation.klass.graphql_meta.type)
                  when Mongoid::Association::Referenced::HasMany
                    relation.klass.graphql_meta.model_resolver
                  else
                    puts "#{relation.class} is not supported!!"
                end
        if result
          fulfill(result)
        end
      end

      def resolve_belongs_to_type
        if relation.polymorphic?

          graphql_types = context.parsed_models.select do |m|
            m.model.relations.any? { |_, field| field.options[:as] == relation.name && field.klass == relation.inverse_class }
          end.map { |m| m.type  }

          type_name = "Possible#{relation.name.capitalize}Type"
          Class.new(GraphQL::Schema::Union) do
            graphql_name type_name
            possible_types *graphql_types
            def self.resolve_type(obj, _ctx)
              obj.class.graphql_meta.type
            end
          end

        else

          context.parsed_models.select do |m|
            m.model == relation.klass
          end&.first&.type

        end
      end
    end
  end
end
