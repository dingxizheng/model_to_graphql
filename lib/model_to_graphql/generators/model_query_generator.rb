# frozen_string_literal: true

require_relative "../objects/field.rb"
require_relative "../types/any_type.rb"
require_relative "../types/raw_json.rb"
require_relative "../types/paged_result_type.rb"

module ModelToGraphql
  module Generators
    unless defined?(GraphQL::Schema::Resolver)
      raise "Graphql is not loaded!!!"
    end

    class ModelQueryGenerator < GraphQL::Schema::Resolver
      argument :page, Integer, required: false, default_value: 1,  prepare: -> (page, _ctx) {
        if page && page >= 99999999
          raise GraphQL::ExecutionError, "page is too big!"
        else
          page
        end
      }
      argument :per,  Integer, required: false, default_value: 10, prepare: -> (per, _ctx) {
        if per && per > 100
          raise GraphQL::ExecutionError, "not allowed to return more than 50 items in one page!"
        else
          per
        end
      }

      # @params filter [Hash]
      def resolve(filter: {}, **args)
        scope = default_scope
        filter.each do |arg, value|
          arg_handler = self.class.query_handlers[arg.to_s]
          if !arg_handler.nil?
            scope = arg_handler.call(scope, value)
          end
        end
        scope = pagination(scope, **args)
        scope = sort(scope, **args)
        OpenStruct.new(
          list:  scope,
          total: 0,
          page:  args[:page]
        )
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
        authorized_scope = self.class.resolve_authorized_scope(context, self.class.model_class)
        if !object.nil? && self.class.current_relation
          base_selector     = authorized_scope.selector
          relation_selector = object.send(self.class.current_relation.name).selector
          self.class.model_class.where(base_selector).and(relation_selector)
        else
          authorized_scope
        end
      end

      # Generate graphql field resolver class
      # @param model Base model class
      # @param return_type The corresponding graphql type of the given model class
      # @param query_type The filter type
      # @param sort_key_enum Suppotted sort keys
      # @param scope_resolver_proc The proc which called to resolve the default scope based on the context.
      def self.to_query_resolver(model, return_type, query_type, sort_key_enum, scope_resolver_proc = nil)
        Class.new(ModelQueryGenerator) do
          scope_resolver scope_resolver_proc
          to_resolve model, query_type
          type ModelToGraphql::Types::PagedResultType[return_type], null: false
          argument :sort, sort_key_enum, required: false
        end
      end

      def self.to_resolve(model, query_type)
        @model_klass = model
        argument(:filter, query_type, required: false)
        @handlers = query_type.argument_hanlders
      end

      def self.model_class
        @model_klass
      end

      def self.query_handlers
        @handlers || {}
      end

      def self.set_relation(relation)
        @relation = relation
      end

      def self.current_relation
        @relation
      end

      def self.scope_resolver(resolver_proc = nil)
        @scope_resolver = resolver_proc
      end

      # Resovle the authorized scope
      # @param context Graphql execution context
      # @param model Base model class
      def self.resolve_authorized_scope(context, model)
        return model if @scope_resolver.nil?
        begin
          return @scope_resolver.call(context, model)
        rescue => e
          puts "Failed to resolve the scope for #{model} when the context is #{context}"
          raise e
        end
      end

      def self.inspect
        "#<Query#{model_class}Resolver>"
      end
    end
  end
end
