# frozen_string_literal: true

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

      def self.to_graphql_type(gl_name, fields, raw_fields = [], guard_proc = nil)
        ModelToGraphql.logger.debug "ModelToGQL | Generating graphql type #{gl_name} ..."
        Class.new(TypeGenerator) do
          graphql_name gl_name
          define_fields fields
          define_raw_fields raw_fields

          @guard_proc = guard_proc
          def self.authorized?(object, context)
            if !@guard_proc.nil? && @guard_proc.is_a?(Proc)
              @guard_proc.call(object, context)
            else
              true
            end
          end

          @gl_name = gl_name
          def self.name
            @gl_name
          end
        end
      end

      def self.name
        super || graphql_name
      end

      def self.inspect
        "#<#{graphql_name}>"
      end

      def self.define_raw_fields(raw_fields = [])
        raw_fields.each do |raw_field|
          field raw_field[:name], raw_field[:type], **raw_field[:options]
          if !raw_field[:block].nil?
            define_method(raw_field[:name]) do
              raw_field[:block].call(object, context)
            end
          end
        end
      end

      Contract C::ArrayOf[ModelToGraphql::Objects::Field] => C::Any
      def self.define_fields(fields)
        fields.each do |f|
          # If it's a id field
          if f.name == :id
            field :id, ID, null: false
          # If resolver is provided
          elsif f.resolver.present?
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
