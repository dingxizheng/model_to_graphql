# frozen_string_literal: true

module ModelToGraphql
  module Loaders
    class HasOneLoader < GraphQL::Batch::Loader
      def initialize(model, query_key, unscoped: false, selector: {})
        @unscoped  = unscoped
        @selector  = selector
        @model     = model
        @query_key = query_key
      end

      def perform(ids)
        if @unscoped
          @model.unscoped { @model.where(@selector).where(:"#{@query_key}_id".in => ids).each { |record| fulfill(record.send(:"#{@query_key}_id")&.to_s, record) } }
        else
          @model.where(@selector).where(:"#{@query_key}_id".in => ids).each { |record| fulfill(record.send(:"#{@query_key}_id")&.to_s, record) }
        end
        ids.each { |id| fulfill(id, nil) unless fulfilled?(id) }
      end
    end
  end
end
