# frozen_string_literal: true

module ModelToGraphql
  module Generators
    class EmbedsManyRelationResolverGenerator < GraphQL::Schema::Resolver

      def resolve
        object.send(relation.name)
      end

      def relation
        self.class.relation
      end

      def self.build(relation, return_type)
        Class.new(EmbedsManyRelationResolverGenerator) do
          type [return_type], null: true
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
