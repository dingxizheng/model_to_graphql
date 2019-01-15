# frozen_string_literal: true

require "model_to_graphql/version"

module ModelToGraphql
  class Error < StandardError; end
  # Your code goes here...

  class << self
    def configure(&block)
    end

    def types
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
require_relative "model_to_graphql/definitions/model_definition.rb"
require_relative "model_to_graphql/generators/type_generator.rb"
require_relative "model_to_graphql/generators/query_type_generator.rb"
require_relative "model_to_graphql/generators/sort_key_enum_generator.rb"
