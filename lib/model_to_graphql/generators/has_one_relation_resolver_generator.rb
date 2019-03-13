# frozen_string_literal: true

require_relative "../loaders/has_one_loader.rb"

module ModelToGraphql
  module Generators

    unless defined?(GraphQL::Schema::Resolver)
      raise "Graphql is not loaded!!!"
    end

    class HasOneRelationResolverGenerator < GraphQL::Schema::Resolver

      def resolve
        ModelToGraphql::Loaders::HasOneLoader.for(relation.klass, relation.name).load(object.id.to_s)
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

      def self.to_relation_resolver(relation, return_type)
        Class.new(HasOneRelationResolverGenerator) do
          type return_type, null: true
          for_relation relation
        end
      end
    end
  end
end
