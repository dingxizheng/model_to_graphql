# frozen_string_literal: true

module ModelToGraphql
  module Generators
    class EmbedsOneRelationResolverGenerator < GraphQL::Schema::Resolver
      def resolve(path: [], lookahead: nil)
        object.send(relation.name)
      end

      def relation
        self.class.relation
      end

      def self.build(relation, return_type)
        klass = Class.new(EmbedsOneRelationResolverGenerator) do
          type return_type, null: true
          for_relation relation
        end
        klass
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
