# frozen_string_literal: true

require "contracts"
require "promise.rb"
require_relative "../objects/field.rb"
require_relative "../types/any_type.rb"
require_relative "../types/raw_json.rb"
require_relative "../types/date_type.rb"

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
        [:integer, Int],
        [:float, Float],
        [:object, String],
        [:boolean, Boolean],
        [:object_id, ID],
        [:date, ModelToGraphql::Types::DateType],
        [:date_time, GraphQL::Types::ISO8601DateTime],
        [:time, GraphQL::Types::ISO8601DateTime],
        [:array, []],
        [:hash, ModelToGraphql::Types::RawJson],
        [:symbol, String]
      ].freeze

      def self.to_graphql_type(name, fields)
        Class.new(TypeGenerator) do
          graphql_name name
          define_fields fields
          def self.name
            name
          end
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
            f.resolver
              .then do |rsl|
                field f.name, resolver: rsl
              end
              .then(nil, proc { |_| puts "#{f.name} is not supported! message: #{ _ }" })

          # If resovler is not a promise
          elsif !f.resolver.nil?
            field f.name, resolver: f.resolver
          else
            field f.name, graphql_prime_type(f.type, f.element), null: f.null?
          end
        rescue => e
          puts "Failed to define field #{ f.inspect }"
          raise e
        end
      end

      # Resolve the graphql prime type of a given field
      def self.graphql_prime_type(type_symbol, ele_symbol)
        graphql_type = TYPE_MAPPINGS.select { |pair| pair.first == type_symbol }&.first&.last
        if graphql_type.is_a? Array
          [element_type(ele_symbol), null: true]
        else
          graphql_type
        end
      end

      def self.element_type(type_symbol)
        return ModelToGraphql::Types::AnyType if type_symbol.nil?
        graphql_prime_type(type_symbol, nil) || ModelToGraphql::Types::AnyType
      end
    end
  end
end
