# frozen_string_literal: true

module ModelToGraphql
  module Generators
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

      def self.build(gl_name, fields, raw_fields = [], guard_proc = nil)
        ModelToGraphql.logger.debug "ModelToGQL | Generating graphql type #{gl_name} ..."
        klass = Class.new(TypeGenerator) do
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
        klass
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
            if f.resolver.is_a? Mongoid::Association::Relatable
              if !f.resolver.klass.nil?
                ModelToGraphql::EventBus.on_ready(f.resolver.klass.name) do
                  ModelToGraphql.logger.debug "ModelToGQL | add resolver on relation[#{f.resolver.name}] for model[#{f.resolver.klass.name}]"
                  resolver = RelationResolver.of(f.resolver).resolve
                  field f.name, resolver: resolver
                rescue => e
                  ModelToGraphql.logger.error "ModelToGQL | failed to add resolver on relation[#{f.resolver.name}] for model[#{f.resolver.klass.name}]"
                  ModelToGraphql.logger.error "ModelToGQL | #{resolver.inspect}, error: #{e.message}"
                end
              elsif f.resolver.polymorphic?
                relation_name = f.resolver.name
                model_names = Mongoid.models.select do |m|
                                m.relations.any? { |_, field| field.options[:as] == relation_name }
                              end.map(&:name)
                ModelToGraphql::EventBus.on_ready(*model_names) do
                  ModelToGraphql.logger.debug "ModelToGQL | add resolver on polymorphic relation[#{f.resolver.name}] for model[#{model_names}]"
                  resolver = RelationResolver.of(f.resolver).resolve
                  field f.name, resolver: resolver
                rescue => e
                  ModelToGraphql.logger.error "ModelToGQL | failed to add resolver on polymorphic relation[#{f.resolver.name}] for model[#{model_names}]"
                  ModelToGraphql.logger.error "ModelToGQL | #{resolver.inspect}, error: #{e.message}"
                end
              end
            else
              field f.name, resolver: f.resolver
            end
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
