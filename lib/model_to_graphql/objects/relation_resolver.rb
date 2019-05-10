# frozen_string_literal: true

require_relative "../generators/belongs_to_relation_resolver_generator.rb"
require_relative "../generators/embeds_one_relation_resolver.rb"
require_relative "../generators/embeds_many_relation_resolver.rb"
require_relative "../generators/has_one_relation_resolver_generator.rb"

module ModelToGraphql
  module Objects
    class RelationResolver
      include ModelToGraphql::Generators

      attr_accessor :relation, :context

      def self.of(relation, context)
        promise = new
        promise.relation = relation
        promise.context  = context
        promise
      end

      def resolve
        case relation
        when Mongoid::Association::Referenced::BelongsTo
          BelongsToRelationResolverGenerator.to_relation_resolver(relation, resolve_belongs_to_type, context.config[:is_relation_unscoped])
        when Mongoid::Association::Embedded::EmbedsOne
          EmbedsOneRelationResolverGenerator.to_relation_resolver(relation, get_model_type(relation.klass))
        when Mongoid::Association::Embedded::EmbedsMany
          EmbedsManyRelationResolverGenerator.to_relation_resolver(relation, get_model_type(relation.klass))
        when Mongoid::Association::Referenced::HasOne
          HasOneRelationResolverGenerator.to_relation_resolver(relation, get_model_type(relation.klass), context.config[:is_relation_unscoped])
        when Mongoid::Association::Referenced::HasMany
          ModelToGraphql::FieldHolders::QueryResolver[relation.klass, "#{relation.inverse_class}#{relation.name}", relation: relation]
        when Mongoid::Association::Referenced::HasAndBelongsToMany
          ModelToGraphql::FieldHolders::QueryResolver[relation.klass, "#{relation.inverse_class}#{relation.name}", relation: relation]
        else
          puts "#{relation.class} is not supported!!"
        end
      end

      def get_model_type(model)
        ModelToGraphql::Types::ModelType[model]
      end

      def resolve_belongs_to_type
        if relation.polymorphic?
          ModelToGraphql::Types::UnionModelType[relation, context]
        else
          get_model_type(relation.klass)
        end
      end
    end
  end
end
