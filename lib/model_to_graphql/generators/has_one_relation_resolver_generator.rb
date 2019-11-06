# frozen_string_literal: true

module ModelToGraphql
  module Generators
    class HasOneRelationResolverGenerator < GraphQL::Schema::Resolver
      class << self
        attr_accessor :relation
      end

      def resolve(path: [], lookahead: nil)
        unscoped = false

        relation_unscoped_proc = ModelToGraphql.config_options[:is_relation_unscoped]
        unless relation_unscoped_proc.nil?
          unscoped = relation_unscoped_proc.call(relation)
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

      def self.build(relation, return_type)
        Class.new(HasOneRelationResolverGenerator) do
          type(return_type, null: true)
          self.relation = relation
        end
      end
    end
  end
end
