# frozen_string_literal: true

module ModelToGraphql
  module Generators
    class BelongsToRelationResolverGenerator < GraphQL::Schema::Resolver
      class << self
        attr_accessor :is_relation_unscoped_proc, :relation
      end

      def resolve
        model_class = relation_model_class(relation, object)
        foreign_key = object.send("#{relation.name}_id")
        unscoped = false

        if self.class.is_relation_unscoped_proc.present?
          unscoped = self.class.is_relation_unscoped_proc.call(relation)
        end

        ModelToGraphql::Loaders::RecordLoader.for(model_class, unscoped: unscoped).load(foreign_key&.to_s)
      end

      def relation_model_class(relation, object)
        self.class.relation_model_class(relation, object)
      end

      def relation
        self.class.relation
      end

      # Resolve the model class of a polymorphic relation
      def self.relation_model_class(relation, object)
        if relation.polymorphic?
          object.send("#{relation.name}_type").constantize
        else
          relation.klass
        end
      end

      def self.build(relation, return_type, is_relation_unscoped_proc = nil)
        klass = Class.new(BelongsToRelationResolverGenerator) do
          type return_type, null: true
          self.is_relation_unscoped_proc = is_relation_unscoped_proc
          self.relation = relation
        end
        klass
      end
    end
  end
end
