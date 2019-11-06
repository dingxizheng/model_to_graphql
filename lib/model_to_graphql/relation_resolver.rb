# frozen_string_literal: true

module ModelToGraphql
  class RelationResolver
    include ModelToGraphql::Generators

    attr_accessor :relation

    def self.of(relation, context = nil)
      instance = new
      instance.relation = relation
      instance
    end

    def resolve
      case relation
      when Mongoid::Association::Referenced::BelongsTo
        BelongsToRelationResolverGenerator.build(relation, resolve_belongs_to_type)
      when Mongoid::Association::Embedded::EmbedsOne
        EmbedsOneRelationResolverGenerator.build(relation, get_model_type(relation.klass))
      when Mongoid::Association::Embedded::EmbedsMany
        EmbedsManyRelationResolverGenerator.build(relation, get_model_type(relation.klass))
      when Mongoid::Association::Referenced::HasOne
        HasOneRelationResolverGenerator.build(relation, get_model_type(relation.klass))
      when Mongoid::Association::Referenced::HasMany
        ModelToGraphql::Objects::QueryResolver[relation.klass]
        # ModelToGraphql::FieldHolders::QueryResolver[relation.klass, "#{relation.inverse_class}#{relation.name}", relation: relation]
      when Mongoid::Association::Referenced::HasAndBelongsToMany
        ModelToGraphql::Objects::QueryResolver[relation.klass]
        # ModelToGraphql::FieldHolders::QueryResolver[relation.klass, "#{relation.inverse_class}#{relation.name}", relation: relation]
      else
        puts "#{relation.class} is not supported!!"
      end
    end

    def get_model_type(model)
      ModelToGraphql::Objects::Type[model]
    end

    def resolve_belongs_to_type
      if relation.polymorphic?
        ModelToGraphql::Objects::BelongsToUnionType[relation]
      else
        get_model_type(relation.klass)
      end
    end
  end
end
