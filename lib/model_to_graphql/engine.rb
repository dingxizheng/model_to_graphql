# frozen_string_literal: true

require "contracts"
require "promise.rb"
require_relative "./objects/relation_resolver_promise.rb"
require_relative "./types/model_type.rb"
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

    attr_accessor :initialized
    attr_accessor :config

    def initialize(config)
      @config      = config
      @initialized = Promise.new
      clean_up
    end

    def clean_up
      @promises = []
      @models   = []
    end

    # Return all models that should be included at the top query type
    def top_level_fields
      Mongoid.models.reject do |model|
        (@config[:excluded_models] | []).include?(model.name) || model.embedded?
      end
    end

    def bootstrap
      Mongoid.models.each do |model|
        ModelToGraphql.logger.debug "ModelToGQL | Processing Model: #{model.name}"
        if (@config[:excluded_models] | []).include?(model.name)
          ModelToGraphql.logger.debug "ModelToGQL | Skipping Model: #{model.name}"
          next
        end
        model_def      = find_model_def(model) || create_model_def(model)
        model_def.discover_links(self)
        fields         = model_def.merged_fields
        custom_filters = model_def.filters || []
        raw_fields     = model_def.raw_fields || []

        model_details = %Q{
Model Definition: #{model_def}
Embeded?:         #{model.embedded?}
Fields:           #{fields.map(&:name)}
Custom Filters:   #{custom_filters.map { |f| f[:name] }}
Raw Fields:       #{raw_fields.map { |f| f[:name] }}
        }

        ModelToGraphql.logger.debug "ModelToGQL | Model details: #{model_details}"

        type      = make_type("#{model.name}Type", fields, raw_fields)
        sort_enum = make_sort_key_enum("#{model.name}SortKey", fields)
        query     = nil
        resolver  = nil
        single_query_resolver = nil
        if !model.embedded?
          query                 = make_query_type("#{model.name}Query", fields, custom_filters)
          query_keys            = make_query_key_enum("#{model.name}QueryKey", query)
          resolver              = make_model_query_resolver(model, type, query, sort_enum)
          single_query_resolver = make_single_query_resolver(model, type)
        end

        model_meta = Model.new(model,
          type:            type,
          query_type:      query,
          model_resolver:  resolver,
          single_resolver: single_query_resolver,
          query_keys:      query_keys
        )
        @models << model_meta
      end

      @promises.each do |promise|
        if (@config[:excluded_models] | []).include?(promise.relation.klass)
          promise.reject "#{promise.relation.klass} is excluded!"
        end
        promise.resolve
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

    def make_mutation
    end

    def find_model_def(model)
      ModelToGraphql.logger.debug "ModelToGQL | Looking for definition for model: #{model.name} ..."
      ModelDefinition.definitions.select { |definition| model == definition.model }&.first
    end

    def create_model_def(model)
      ModelToGraphql.logger.debug "ModelToGQL | Creating definition for model: #{model.name} ..."
      Class.new(ModelDefinition) do
        define_for_model model
      end
    end

    def relation_resolver(relation)
      promise = RelationResolverPromise.of(relation, self)
      @promises << promise
      promise
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
  end
end
