# frozen_string_literal: true

require "contracts"
require_relative "./objects/relation_resolver.rb"
require_relative "./types/model_type.rb"
require_relative "./types/union_model_type.rb"
require_relative "./generators/type_generator.rb"
require_relative "./generators/sort_key_enum_generator.rb"
require_relative "./generators/query_type_generator.rb"
require_relative "./generators/single_record_query_generator.rb"
require_relative "./objects/return_type_instrumentor.rb"

module ModelToGraphql
  class Engine
    include ModelToGraphql::Generators
    include ModelToGraphql::Objects
    include ModelToGraphql::Definitions
    include ModelToGraphql::Types
    include Contracts::Core
    C = Contracts

    attr_accessor :config

    def initialize(config)
      @config      = config
      @model_names = nil
      @model_defintions_names = nil
      @models      = []
      clean_up
    end

    def clean_up
      ModelToGraphql::Types::ModelType.clear
      ModelToGraphql::Types::UnionModelType.clear
      ModelToGraphql::FieldHolders::QueryResolver.clear
      ModelToGraphql::FieldHolders::SingleResolver.clear
      ModelToGraphql::FieldHolders::QueryKeyResolver.clear
      # ModelDefinition.clear_descendants
      @models   = []
    end

    # Return all models that should be included at the top query type
    def top_level_fields
      collect_model_names
      @model_names.reject do |model_name|
        model = model_name.safe_constantize
        (@config[:excluded_models] | []).include?(model_name) || model&.embedded?
      end
    end

    def collect_model_names
      # Load all models
      Dir[File.join(Rails.root, "app/models", "**", "*.rb")].each do |file|
        require_dependency file
      end
      @model_names = Mongoid.models.map(&:name).uniq
    end

    def collect_model_definitions_names
      @model_defintions_names = ModelDefinition.definitions.map(&:name).compact
    end

    def bootstrap
      collect_model_names
      collect_model_definitions_names
      @model_names.each do |model_name|
        model = model_name.safe_constantize

        ModelToGraphql.logger.debug "ModelToGQL | Processing Model: #{model.name}"
        if model.nil? || (@config[:excluded_models] | []).include?(model.name)
          ModelToGraphql.logger.debug "ModelToGQL | Skipping Model: #{model.name}"
          next
        end

        model_def      = find_model_def(model)&.safe_constantize || create_model_def(model)
        model_def.discover_links(self)
        fields         = model_def.merged_fields
        custom_filters = model_def.filters || []
        raw_fields     = model_def.raw_fields || []

        ModelToGraphql.logger.debug "ModelToGQL | Making graphql type for #{model} ..."

        type      = make_type("#{model_name(model)}Type", fields, raw_fields)
        sort_enum = make_sort_key_enum("#{model_name(model)}SortKey", fields)
        query     = nil
        model_resolver  = nil
        single_resolver = nil

        if !model.embedded?
          return_type           = ModelToGraphql::Types::ModelType[model]
          query                 = make_query_type("#{model_name(model)}Query", fields, custom_filters)
          query_keys            = make_query_key_enum("#{model_name(model)}QueryKey", query)
          model_resolver        = make_model_query_resolver(model, type, query, sort_enum)
          single_resolver       = make_single_query_resolver(model, type)
        end

        model_meta = Model.new(model,
          type:            type,
          query_type:      query,
          model_resolver:  model_resolver,
          single_resolver: single_resolver,
          query_keys:      query_keys
        )
        @models << model_meta
      end
      self
    end

    def make_type(name, fields, raw_fields)
      TypeGenerator.to_graphql_type(name, fields, raw_fields, @config[:authorize_object])
    end

    def make_query_type(name, fields, custom_filters = [])
      QueryTypeGenerator.to_graphql_type(name, fields, custom_filters)
    end

    def make_model_query_resolver(model, return_type, query_type, sort_enum)
      ModelQueryGenerator.to_query_resolver(model, return_type, query_type, sort_enum, @config[:list_scope])
    end

    def make_single_query_resolver(model, return_type)
      SingleRecordQueryGenerator.to_query_resolver(model, return_type)
    end

    def make_sort_key_enum(name, fields)
      SortKeyEnumGenerator.to_graphql_enum(name, fields)
    end

    def make_query_key_enum(gl_name, query)
      Class.new(GraphQL::Schema::Enum) do
        graphql_name gl_name
        query.arguments.keys.each do |name, _|
          value name, "Query key #{name}"
        end
      end
    end

    def find_model_def(model)
      ModelToGraphql.logger.debug "ModelToGQL | Looking for definition for model: #{model.name} ..."
      @model_defintions_names.select do |definition_name|
        definition = definition_name.safe_constantize
        model == definition.model
      end&.first
    end

    def create_model_def(model)
      ModelToGraphql.logger.debug "ModelToGQL | Creating definition for model: #{model.name} ..."
      Class.new(ModelDefinition) do
        define_for_model model
      end
    end

    def relation_resolver(relation)
      RelationResolver.of(relation, self).resolve
    end

    def find_meta(model_class)
      @models.select { |m| m.model.name == model_class.name }&.first
    end

    def parsed_models
      @models || []
    end

    def meta_type_of(model_class)
      parsed_models.select { |m| m.model.name == model_class.name }&.first
    end

    def type_of(model_class)
      meta_type_of(model_class).type
    end

    def return_type_instrumentor
      ReturnTypeInstrumentor.new(method(:meta_type_of).to_proc)
    end

    def model_name(model)
      model.name.delete("::")
    end
  end
end
