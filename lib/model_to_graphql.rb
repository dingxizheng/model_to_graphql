# frozen_string_literal: true

require "mongoid"
require "graphql"
require "model_to_graphql/version"

module ModelToGraphql
  class Error < StandardError; end
  # Your code goes here...

  class << self
    def configure(&block)
      instance_eval(&block)
    end

    # Define which orm framework to be used.
    # Mongoid is set as default
    # 
    # @param orm [Symbol]
    # @return nil
    def use_orm(orm = :mongoid)
      config(:orm, orm)
    end

    def model_scan_dir(model_scan_dir)
      config(:model_dir, model_scan_dir)
    end

    def exclude_models(*models_to_excluded)
      config(:excluded_models, models_to_excluded)
    end

    def model_definition_scan_dir(model_def_scan_dir)
      config(:model_def_dir, model_def_scan_dir)
    end

    def config(key, val)
      @config ||= {}
      @config[key.to_sym] = val
    end

    def config_options
      @config || {}
    end
  end
end

if defined?(Mongoid) && defined?(Mongoid::Fields)
  # Add additional mongoid field options
  require_relative "mongoid_setup.rb"
end

require_relative "graphql_setup.rb"
require_relative "model_to_graphql/objects/field.rb"
require_relative "model_to_graphql/objects/link.rb"
require_relative "model_to_graphql/objects/model.rb"
require_relative "model_to_graphql/definitions/model_definition.rb"
require_relative "model_to_graphql/generators/type_generator.rb"
require_relative "model_to_graphql/generators/query_type_generator.rb"
require_relative "model_to_graphql/generators/sort_key_enum_generator.rb"
require_relative "model_to_graphql/generators/model_query_generator.rb"
require_relative "model_to_graphql/engine.rb"
require_relative "model_to_graphql/types/any_type.rb"
