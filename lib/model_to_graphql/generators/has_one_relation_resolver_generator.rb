# frozen_string_literal: true

require_relative "../loaders/has_one_loader.rb"

module ModelToGraphql
  module Generators
    unless defined?(GraphQL::Schema::Resolver)
      raise "Graphql is not loaded!!!"
    end

    class HasOneRelationResolverGenerator < GraphQL::Schema::Resolver
      class << self
        attr_accessor :is_relation_unscoped_proc, :relation
      end

      def resolve
        unscoped = false

        if self.class.is_relation_unscoped_proc.present?
          unscoped = self.class.is_relation_unscoped_proc.call(relation)
        end

        if unscoped
          ModelToGraphql::Loaders::HasOneLoader.for(relation.klass.unscoped, relation.inverse.to_s).load(object.id.to_s)
        else
          ModelToGraphql::Loaders::HasOneLoader.for(relation.klass, relation.inverse.to_s).load(object.id.to_s)
        end
      end

      def relation
        self.class.relation
      end

      def self.to_relation_resolver(relation, return_type, is_relation_unscoped_proc = nil)
        Class.new(HasOneRelationResolverGenerator) do
          type return_type, null: true
          self.is_relation_unscoped_proc = is_relation_unscoped_proc
          self.relation = relation
        end
      end
    end
  end
end
