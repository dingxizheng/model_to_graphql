# frozen_string_literal: true
require "contracts"

module ModelToGraphql
  class Error < StandardError; end

  class << self
    def configure(&block)
      instance_eval(&block)

      Rails.application.config.after_initialize do |_app|
        ModelToGraphql.mount_queries
        ModelToGraphql::EventBus.fulfill_unfired_requests

        ActiveSupport::Reloader.after_class_unload do
          ModelToGraphql::EventBus.clear
          ModelToGraphql.clear_constants
        end

        ActiveSupport::Reloader.to_prepare do
          ModelToGraphql.mount_queries
          ModelToGraphql::EventBus.fulfill_unfired_requests
        end
      end
    end

    def clear_constants
      const_namspaces = [
        ModelToGraphql::Objects::BelongsToUnionType,
        ModelToGraphql::Objects::Type,
        ModelToGraphql::Objects::QueryType,
        ModelToGraphql::Objects::QueryResolver,
        ModelToGraphql::Objects::RecordResolver,
        ModelToGraphql::Objects::QueryKey,
        ModelToGraphql::Objects::SortKey,
        ModelToGraphql::Objects::ModelDefinition,
        ModelToGraphql::Objects::PagedResult,
        ModelToGraphql::Types::ModelType
      ]
      const_namspaces.each do |namespace|
        ModelToGraphql.logger.debug "ModelToGQL | clear constants for #{namespace}..."
        namespace.remove_all_constants if namespace.respond_to?(:remove_all_constants)
      end
    end

    def mount_queries
      query_type = config_options[:query_type].constantize
      query_type.mount_queries
    end

    def query_fields
      @model_names ||= Mongoid.models.map(&:name).uniq
      @model_names.reject do |model_name|
        model = model_name.constantize
        (config_options[:excluded_models] | []).include?(model_name) || model&.embedded?
      end
    end

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

    def mount_queries_to(query_type)
      config(:query_type, query_type.is_a?(String) ? query_type : query_type.name)
    end

    def define_for_schema(schema)
      config(:schema, schema.is_a?(String) ? schema : query_type.name)
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


require "model_to_graphql/version"
require "model_to_graphql/setup/setup"

# Contracts
require "model_to_graphql/contracts/contracts"

require "model_to_graphql/event_bus"

# Types
require "model_to_graphql/types/model_type"
require "model_to_graphql/types/any_type"
require "model_to_graphql/types/date_type"
require "model_to_graphql/types/float"
require "model_to_graphql/types/paged_result_type"
require "model_to_graphql/types/raw_json"

# Objects
require "model_to_graphql/objects/model_definition"
require "model_to_graphql/objects/helper"
require "model_to_graphql/objects/field"
require "model_to_graphql/objects/type"
require "model_to_graphql/objects/query_key"
require "model_to_graphql/objects/sort_key"
require "model_to_graphql/objects/query_type"
require "model_to_graphql/objects/query_resolver"
require "model_to_graphql/objects/record_resolver"
require "model_to_graphql/objects/belongs_to_union_type"
require "model_to_graphql/objects/paged_result"

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
require "model_to_graphql/definitions/model_definition"