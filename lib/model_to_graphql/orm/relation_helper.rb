# frozen_string_literal: true

module ModelToGraphql
  module ORM
    module RelationHelper
      def resolve_belongs_to_classes(relation)
        if relation.polymorphic?
          resolve_polymorphic_classes(relation)
        else
          relation.klass
        end
      end

      def resolve_polymorphic_classes(relation)
        Mongoid.models.select do |m|
          m.relations.any? do |_key, model_relation|
            model_relation.polymorphic? && model_relation.options[:as] == relation.name && model_relation.klass == relation.inverse_class
          end
        end
      end
    end
  end
end
