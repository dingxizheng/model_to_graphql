# frozen_string_literal: true

require "contracts"
require "promise.rb"
require_relative "../objects/field.rb"
require_relative "../objects/any_type.rb"
require_relative "../objects/raw_json.rb"

module ModelToGraphql
  module Generators

    unless defined?(GraphQL::Schema::Resolver)
      raise "Graphql is not loaded!!!"
    end

    class ModelQueryGenerator < GraphQL::Schema::Resolver
      include Contracts::Core
      C = Contracts

      argument :page,    Integer, required: false, default_value: 1
      argument :per,     Integer, required: false, default_value: 10
      argument :sort,    String,  required: false

      def resolve(filter: {}, **args)
        scope = default_scope

        filter.each do |arg, value|
          arg_handler = @handlers[arg]
          if !arg_handler.nil?
            scope = arg_handler.call(scope, value)
          end
        end
        scope = pagination(scope, **args)
        scope = sort(scope, **args)
        scope
      end

      def pagination(scope, page:, per:, **kwargs)
        scope.page(page).per(per)
      end

      def sort(scope, sort: nil, **kwargs)
        return scope if sort.nil?
        if sort.end_with? "_desc"
          scope.order_by("#{sort[0..-6]}": :desc)
        else
          scope.order_by("#{sort[0..-5]}": :asc)
        end
      end

      def default_scope
        if !object.nil?
          relation = object.class.relations.select do |_, re|
            re.class.ancestors.include?(Mongoid::Association::Referenced::HasMany) && re.klass == self.class.model_class
          end&.first
          object.send(relation[0])
        else
          self.class.model_class
        end
      end

      def self.resolve_model(model, query_type)
        @model_klass = model
        argument(:filter, query_type, required: false)
        @handlers = query_type.argument_hanlders
      end

      def self.model_class
        @model_klass
      end
    end
  end
end
