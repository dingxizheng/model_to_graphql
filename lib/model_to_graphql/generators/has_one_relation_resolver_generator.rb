# frozen_string_literal: true

require_relative "../loaders/has_one_loader.rb"

module ModelToGraphql
  module Generators

    unless defined?(GraphQL::Schema::Resolver)
      raise "Graphql is not loaded!!!"
    end

    class HasOneRelationResolverGenerator < GraphQL::Schema::Resolver

      def resolve
        if relation.klass
          selected_pair = relation.klass.relations.select { |pair| relation.klass < pair[1].klass && pair[1].is_a?(Mongoid::Association::Referenced::BelongsTo) }
          relation_name = selected_pair[0]
        end
        raise StandardError, "Not able to resolve the inverse relation_nmae of has_one relation #{relation.name} on model #{relation.klass}" if relation_name.nil?
        ModelToGraphql::Loaders::HasOneLoader.for(relation.klass, relation_name).load(object.id.to_s)
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
