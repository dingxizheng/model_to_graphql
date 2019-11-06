# frozen_string_literal: true

module ModelToGraphql
  module Generators
    class TypeGenerator < GraphQL::Schema::Object

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

      def self.build(gl_name, fields, raw_fields = [])
        ModelToGraphql.logger.debug "ModelToGQL | Generating graphql type #{gl_name} ..."
        Class.new(TypeGenerator) do
          graphql_name(gl_name)
          define_fields(fields, raw_fields)
          define_raw_fields(raw_fields)

          def self.authorized?(object, context)
            guard_proc = ModelToGraphql.config_options[:authorize_object]
            if !guard_proc.nil?
              guard_proc.call(object, context)
            else
              true
            end
          end

          def self.name
            gl_name
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
          field_return_type = raw_field[:type]
          if field_return_type.is_a?(Class) && field_return_type < ModelToGraphql::Types::ModelType
            actual_class_name = field_return_type.model_class.name
            ModelToGraphql::EventBus.on_ready(actual_class_name) do
              field(raw_field[:name], ModelToGraphql::Objects::Type[actual_class_name], **raw_field[:options])
            end
          else
            field(raw_field[:name], field_return_type, **raw_field[:options])
          end
          # Define resolver method for the field
          if !raw_field[:block].nil?
            define_method(raw_field[:name]) do
              raw_field[:block].call(object, context)
            end
          end
        end
      end

      def self.define_fields(fields, raw_fields = [])
        fields.reject do |field|
          raw_fields.any? { |raw_field| raw_field[:name].to_s == field.name.to_s }
        end.each do |f|
          if f.name == :id
            # If it's a id field
            field(:id, ID, null: false)
          elsif f.resolver.present?
            # If resolver is provided
            if f.resolver.is_a? Mongoid::Association::Relatable
              if !f.resolver.klass.nil?
                ModelToGraphql::EventBus.on_ready(f.resolver.klass.name) do
                  ModelToGraphql.logger.debug "ModelToGQL | add resolver on relation[#{f.resolver.name}] for model[#{f.resolver.klass.name}]"
                  resolver = RelationResolver.of(f.resolver).resolve
                  field(f.name, extras: [:path, :lookahead], resolver: resolver)
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
                  field(f.name, extras: [:path, :lookahead], resolver: resolver)
                rescue => e
                  ModelToGraphql.logger.error "ModelToGQL | failed to add resolver on polymorphic relation[#{f.resolver.name}] for model[#{model_names}]"
                  ModelToGraphql.logger.error "ModelToGQL | #{resolver.inspect}, error: #{e.message}"
                end
              end
            else
              field(f.name, resolver: f.resolver)
            end
          else
            field(f.name, graphql_prime_type(f.type, f.element), null: f.null?)
          end
        rescue => e
          ModelToGraphql.logger.error "Failed to define field #{ f.inspect }"
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
