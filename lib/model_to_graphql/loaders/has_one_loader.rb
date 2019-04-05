module ModelToGraphql
  module Loaders
    class HasOneLoader < GraphQL::Batch::Loader
      def initialize(model, query_key)
        @model = model
        @query_key = query_key
      end

      def perform(ids)
        @model.where(:"#{@query_key}_id".in => ids).each { |record| fulfill(record.send(:"#{@query_key}_id")&.to_s, record) }
        ids.each { |id| fulfill(id, nil) unless fulfilled?(id) }
      end
    end
  end
end