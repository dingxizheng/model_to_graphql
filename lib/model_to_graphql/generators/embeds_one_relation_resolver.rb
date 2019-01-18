# frozen_string_literal: true

module ModelToGraphql
  module Generators

    unless defined?(GraphQL::Schema::Resolver)
      raise "Graphql is not loaded!!!"
    end

    class EmbedsOneRelationResolverGenerator < GraphQL::Schema::Resolver

      def resolve
        object.send(relation.name)
      end

      def relation
        self.class.relation
      end

      def self.to_relation_resolver(relation, return_type)
        Class.new(EmbedsOneRelationResolverGenerator) do
          type return_type, null: true
          for_relation relation
        end
      end

      def self.for_relation(relation)
        @relation = relation
      end

      def self.relation
        @relation
      end
    end
  end
end
