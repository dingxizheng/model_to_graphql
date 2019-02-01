# frozen_string_literal: true

require "contracts"
require "promise.rb"
require_relative "./objects/relation_resolver_promise.rb"
require_relative "./generators/type_generator.rb"
require_relative "./generators/sort_key_enum_generator.rb"
require_relative "./generators/query_type_generator.rb"
require_relative "./generators/single_record_query_generator.rb"

module ModelToGraphql
  class Engine
    include ModelToGraphql::Generators
    include ModelToGraphql::Objects
    include ModelToGraphql::Definitions
    include Contracts::Core
    C = Contracts

    attr_accessor :initialized

    def initialize(config)
      @config = config
      @promises = []
      @models = []
      @initialized = Promise.new
    end

    Contract String => C::Any
    def scan_models(model_path)
      # Load all models
      Dir[File.join(model_path, "*.rb")].each do |file|
        require file
      end
    end

    Contract String => C::Any
    def scan_model_definitions(model_def_path)
      # Load all models
      Dir[File.join(model_def_path, "*.rb")].each do |file|
        require file
      end
    end

    def bootstrap
      # scan_models(@config[:model_dir])
      scan_model_definitions(@config[:model_def_dir])
      Mongoid.models.each do |model|
        next if (@config[:excluded_models] | []).include?(model)

        model_def = find_model_def(model) || create_model_def(model)
        model_def.discover_links(self)
        fields = model_def.merged_fields

        type     = make_type("#{model.name}Type", fields)
        sort_enum= make_sort_key_enum("#{model.name}SortKey", fields)
        query    = nil
        resolver = nil
        single_query_resolver = nil
        if !model.embedded?
          query                 = make_query_type("#{model.name}Query", fields)
          query_keys            = make_query_key_enum("#{model.name}QueryKey", query)
          resolver              = make_model_query_resolver(model, type, query, sort_enum)
          single_query_resolver = make_single_query_resolver(model, type)
        end

        model_meta = Model.new(model, 
          type: type, 
          query_type: query, 
          model_resolver: resolver, 
          single_resolver: single_query_resolver,
          query_keys: query_keys
        )
        @models << model_meta
      end

      @promises.each do |promise|
        if (@config[:excluded_models] | []).include?(promise.relation.klass)
          promise.reject "#{promise.relation.klass} is excluded!"
        end
        promise.resolve
      end
      initialized.fulfill(@models)
      self
    end

    def make_type(name, fields)
      TypeGenerator.to_graphql_type(name, fields)
    end

    def make_query_type(name, fields)
      QueryTypeGenerator.to_graphql_type(name, fields)
    end

    def make_model_query_resolver(model, return_type, query_type, sort_enum)
      ModelQueryGenerator.to_query_resolver(model, return_type, query_type, sort_enum)
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
      ModelDefinition.definitions.select { |definition| model == definition.model }&.first
    end

    def create_model_def(model)
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
      @models.select { |m| m.model == model_class }&.first
    end

    def parsed_models
      @models || []
    end

    def types
      graphql_models = @models

      # Generate a class methods module
      class_methods_module = Module.new do
        @@_graphql_models = graphql_models

        def type_of(model_class)
          meta_type_of(model_class).type
        end

        def meta_type_of(model_class)
          @@_graphql_models.select { |m| m.model == model_class }&.first
        end
      end

      # Generate the module which could be included into other classes
      Module.new do
        @@class_methods_module = class_methods_module
        def self.extend_object(obj)
          super # important
        end
        def self.included(base)
          base.extend(@@class_methods_module)
        end
      end
    end

  end
end
