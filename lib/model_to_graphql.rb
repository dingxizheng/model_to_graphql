# frozen_string_literal: true
require "promise"
require "contracts"

module ModelToGraphql

  require "model_to_graphql/version"
  require "model_to_graphql/setup/setup"

  require "model_to_graphql/object_cache"

  # Contracts
  require "model_to_graphql/contracts/contracts"

  # Types
  require "model_to_graphql/types/model_type"
  require "model_to_graphql/types/any_type"
  require "model_to_graphql/types/date_type"
  require "model_to_graphql/types/float"
  require "model_to_graphql/types/paged_result_type"
  require "model_to_graphql/types/raw_json"
  require "model_to_graphql/types/union_model_type"

  # Objects
  require "model_to_graphql/objects/field"
  require "model_to_graphql/objects/model"

  # Field Place Holders
  require "model_to_graphql/field_holders/base_resolver"
  require "model_to_graphql/field_holders/query_key_resolver"
  require "model_to_graphql/field_holders/query_resolver"
  require "model_to_graphql/field_holders/single_resolver"

  # Loaders
  require "model_to_graphql/loaders/has_one_loader"
  require "model_to_graphql/loaders/record_loader"

  # GraphQL Class Generators
  require "model_to_graphql/generators/type_generator"
  require "model_to_graphql/generators/query_type_generator"
  require "model_to_graphql/generators/model_query_generator"
  require "model_to_graphql/generators/single_record_query_generator"
  require "model_to_graphql/generators/sort_key_enum_generator"
  require "model_to_graphql/generators/has_one_relation_resolver_generator"
  require "model_to_graphql/generators/belongs_to_relation_resolver_generator"
  require "model_to_graphql/generators/embeds_one_relation_resolver"
  require "model_to_graphql/generators/embeds_many_relation_resolver"

  require "model_to_graphql/relation_resolver"
  require "model_to_graphql/return_type_instrumentor"

  require "model_to_graphql/definitions/model_definition"
  require "model_to_graphql/engine"

  class Error < StandardError; end

  class << self
    def configure(&block)
      instance_eval(&block)
    end

    # Define which orm framework to be used.
    # Mongoid is set as default
    #
    # @param orm [Symbol]
    def use_orm(orm = :mongoid)
      config(:orm, orm)
    end

    # Define all the models should be excluded from the schema
    def exclude_models(*models_to_be_excluded)
      config(:excluded_models, models_to_be_excluded)
    end

    def model_definition_scan_dir(model_def_scan_dir)
      config(:model_def_dir, model_def_scan_dir)
    end

    def is_relation_unscoped(proc = nil, &block)
      if proc.is_a? Proc
        config(:is_relation_unscoped, proc)
      elsif block_given?
        config(:is_relation_unscoped, block)
      else
        raise ArgumentError, "Proc must be provided!"
      end
    end

    # Pass an proc to resolve if current query is allowed
    def authorize_action(proc = nil, &block)
      if proc.is_a? Proc
        config(:authorize_action, proc)
      elsif block_given?
        config(:authorize_action, block)
      else
        raise ArgumentError, "Proc must be provided!"
      end
    end

    # Pass an proc to resolve if current query is allowed
    def authorize_object(proc = nil, &block)
      if proc.is_a? Proc
        config(:authorize_object, proc)
      elsif block_given?
        config(:authorize_object, block)
      else
        raise ArgumentError, "Proc must be provided!"
      end
    end

    def list_scope(proc = nil, &block)
      if proc.is_a? Proc
        config(:list_scope, proc)
      elsif block_given?
        config(:list_scope, block)
      else
        raise ArgumentError, "Proc must be provided!"
      end
    end

    def config(key, val)
      @config ||= {}
      @config[key.to_sym] = val
    end

    def config_options
      @config || {}
    end

    def logger
      @logger ||= defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
    end

    def logger=(logger)
      @logger = logger
    end

    def level=(level)
      logger.level = level
    end
  end
end
