# frozen_string_literal: true

require "contracts"
require "promise.rb"
require_relative "../objects/field.rb"
require_relative "../objects/any_type.rb"
require_relative "../objects/raw_json.rb"

module ModelToGraphql
  module Generators

    unless defined?(GraphQL::Schema::Object)
      raise "Graphql is not loaded!!!"
    end

    class TypeGenerator < GraphQL::Schema::Object
      include Contracts::Core
      C = Contracts

      TYPE_MAPPINGS = [
        [:string, String],
        [:interger, Int],
        [:float, Float],
        [:boolean, Boolean],
        [:object_id, ID],
        [:date, GraphQL::Types::ISO8601DateTime],
        [:date_time, GraphQL::Types::ISO8601DateTime],
        [:time, GraphQL::Types::ISO8601DateTime],
        [:array, []],
        [:hash, ModelToGraphql::Objects::RawJson]
      ].freeze

      def self.to_graphql_type(name, fields)
        Class.new(TypeGenerator) do
          graphql_name name
          define_fields fields
        end
      end

      def self.name
        super || graphql_name
      end

      Contract C::ArrayOf[ModelToGraphql::Objects::Field] => C::Any
      def self.define_fields(fields)
        fields.each do |f|
          # If it's a id field
          if f.name == :id
            field :id, ID, null: false
          # If resolver is provided
          elsif !f.resolver.nil? && f.resolver.is_a?(Promise)
            # Wait until resolver promise is resolved
            f.resolver.then do |rsl|
              field f.name, resolver: rsl
            end
          # If resovler is not a promise
          elsif !f.resolver.nil?
            field f.name, resolver: f.resolver
          else
            field f.name, graphql_prime_type(f), null: f.null?
          end
        end
      end

      # Resolve the graphql prime type of a given field
      def self.graphql_prime_type(field)
        graphql_type = TYPE_MAPPINGS.select { |pair| pair.first == field.type }&.first&.last
        if graphql_type.is_a? Array
          [element_type(field), null: true]
        else
          graphql_type
        end
      end

      def self.element_type(field)
        return ModelToGraphql::Objects::AnyType if field.element_type.nil?
        graphql_prime_type(field) || ModelToGraphql::Objects::AnyType
      end
    end
  end
end
