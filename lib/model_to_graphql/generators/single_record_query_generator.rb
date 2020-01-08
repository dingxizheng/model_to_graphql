# frozen_string_literal: true

module ModelToGraphql
  module Generators
    class SingleRecordQueryGenerator < GraphQL::Schema::Resolver

      argument :id, ID, required: true
      argument :unscope, Boolean, required: false, default_value: false

      def authorized?(*args)
        return true if !object.nil?
        guard_proc = ModelToGraphql.config_options[:authorize_action]
        if !guard_proc.nil? && guard_proc.is_a?(Proc)
          return guard_proc.call(object, args[0], context, :view_model, klass)
        end
        true
      end

      def resolve(path: [], lookahead: nil, id: ni, unscope: false)
        ModelToGraphql::Loaders::RecordLoader.for(klass, unscoped: unscope).load(id)
      end

      def klass
        self.class.klass
      end

      def self.build(klass, return_type)
        ModelToGraphql.logger.debug "ModelToGQL | Generating single record resolver #{klass.name} ..."
        Class.new(SingleRecordQueryGenerator) do
          type(return_type, null: true)
          for_class(klass)
        end
      end

      def self.for_class(klass)
        @klass = klass
      end

      def self.klass
        @klass
      end

      def self.inspect
        "#<Single#{klass}Resolver>"
      end
    end
  end
end
