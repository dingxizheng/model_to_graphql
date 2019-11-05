# frozen_string_literal: true

module ModelToGraphql
  module Generators
    class HasOneRelationResolverGenerator < GraphQL::Schema::Resolver
      class << self
        attr_accessor :is_relation_unscoped_proc, :relation
      end

      def resolve(path: [], lookahead: nil)
        unscoped = false

        if self.class.is_relation_unscoped_proc.present?
          unscoped = self.class.is_relation_unscoped_proc.call(relation)
        end

        if unscoped
          ModelToGraphql::Loaders::HasOneLoader.for(relation.klass, relation.inverse.to_s, unscoped: true).load(object.id.to_s)
        else
          ModelToGraphql::Loaders::HasOneLoader.for(relation.klass, relation.inverse.to_s).load(object.id.to_s)
        end
      end

      def relation
        self.class.relation
      end

      def self.build(relation, return_type, is_relation_unscoped_proc = nil)
        klass = Class.new(HasOneRelationResolverGenerator) do
          type return_type, null: true
          self.is_relation_unscoped_proc = is_relation_unscoped_proc
          self.relation = relation
        end
        klass
      end
    end
  end
end
