# frozen_string_literal: true

require "contracts"
require "promise.rb"
require_relative "../objects/field.rb"
require_relative "../types/any_type.rb"
require_relative "../types/raw_json.rb"
require_relative "../types/date_type.rb"

module ModelToGraphql
  module Generators

    unless defined?(GraphQL::Schema::InputObject)
      raise "Graphql is not loaded!!!"
    end

    class QueryTypeGenerator < GraphQL::Schema::InputObject
      include Contracts::Core
      C = Contracts

      def self.to_graphql_type(name, fields)
        Class.new(QueryTypeGenerator) do
          graphql_name name
          define_arguments fields
          def self.name
            name
          end
        end
      end

      def self.name
        super || graphql_name
      end

      def self.argument_hanlders
        @argument_hanlders || {}
      end

      Contract C::ArrayOf[ModelToGraphql::Objects::Field] => C::Any
      def self.define_arguments(fields)
        @argument_hanlders = {}
        fields.select { |f| f.filterable }
              .each(&method(:make_argument))
      end

      def self.make_argument_resolver(arg_name, field_name, operator = nil)
        @argument_hanlders[arg_name.to_s] = -> (scope, value) {
          if operator.nil?
            scope.where("#{field_name}": value)
          elsif operator.to_s == "regex"
            scope.where("#{field_name}": { "$#{operator}": /#{value}/ })
          else
            scope.where("#{field_name}": { "$#{operator}": value })
          end
        }
      end

      def self.query_argument(field, operator, arg_name, *args, **karges)
        argument(arg_name, *args, **karges)
        make_argument_resolver(arg_name, field.name, operator)
      end

      def self.make_string_argument(field)
        if !field.text
          query_argument field, nil, field.name.to_sym,   String, required: false, camelize: false
          query_argument field, :ne, :"#{field.name}_ne", String, required: false, camelize: false
          query_argument field, :in, :"#{field.name}_in", [String], required: false, camelize: false
        end
        # don't show has filter for id field
        if !field.name.to_s.end_with?("_id")
          query_argument field, :regex, :"#{field.name}_has", String, required: false, camelize: false
        end
      end

      def self.make_boolean_argument(field)
        query_argument field, nil, field.name.to_sym, Boolean, required: false, camelize: false
      end

      def self.make_computable_argument(field, type)
        query_argument field, nil,  field.name.to_sym,    type, required: false, camelize: false
        query_argument field, :ne,  :"#{field.name}_ne",  type, required: false, camelize: false
        query_argument field, :lt,  :"#{field.name}_lt",  type, required: false, camelize: false
        query_argument field, :gt,  :"#{field.name}_gt",  type, required: false, camelize: false
        query_argument field, :gte, :"#{field.name}_gte", type, required: false, camelize: false
        query_argument field, :lte, :"#{field.name}_lte", type, required: false, camelize: false
      end

      def self.make_time_argument(field, type)
        query_argument field, :gte, :"#{field.name}_gte", type, required: false, camelize: false
        query_argument field, :lte, :"#{field.name}_lte", type, required: false, camelize: false
      end

      def self.make_array_argument(field)
        query_argument field, nil, field.name.to_sym, Float, required: false, camelize: false
        # argument :"#{field.name}_ne", Float, required: false, camelize: false
        # argument :"#{field.name}_lt", Float, required: false, camelize: false
        # argument :"#{field.name}_gt", Float, required: false, camelize: false
        # argument :"#{field.name}_ge", Float, required: false, camelize: false
        # argument :"#{field.name}_le", Float, required: false, camelize: false
      end

      def self.make_id_argument(field)
        query_argument field, nil, field.name.to_sym, String, required: false, camelize: false
      end

      def self.make_argument(field)
        case field.type
        when :id
          make_id_argument(field)
        when :string, :symbol, :object_id
          make_string_argument(field)
        when :integer
          make_computable_argument(field, Integer)
        when :boolean
          make_boolean_argument(field)
        when :float
          make_computable_argument(field, Float)
        when :date
          make_time_argument(field, ModelToGraphql::Types::DateType)
        when :time, :date_time
          make_time_argument(field, GraphQL::Types::ISO8601DateTime)
        end
      end
    end
  end
end
