# frozen_string_literal: true

require_relative "../loaders/record_loader.rb"

module ModelToGraphql
  module Generators

    unless defined?(GraphQL::Schema::Resolver)
      raise "Graphql is not loaded!!!"
    end

    class BelongsToRelationResolverGenerator < GraphQL::Schema::Resolver

      def resolve
        model_class = relation_model_class(relation, object)
        foreign_key = object.send("#{relation.name}_id")
        ModelToGraphql::Loaders::RecordLoader.for(model_class).load(foreign_key&.to_s)
      end

      def relation_model_class(relation, object)
        self.class.relation_model_class(relation, object)
      end

      def relation
        self.class.relation
      end

      def self.for_relation(relation)
        @relation = relation
      end

      def self.relation
        @relation
      end

      # Resolve the model class of a polymorphic relation
      def self.relation_model_class(relation, object)
        if relation.polymorphic?
          object.send("#{relation.name}_type").constantize
        else
          relation.klass
        end
      end

      def self.to_relation_resolver(relation, return_type)
        Class.new(BelongsToRelationResolverGenerator) do
          type return_type, null: true
          for_relation relation
        end
      end
    end
  end
end
