# frozen_string_literal: true

module ModelToGraphql
  module Loaders
    class RecordLoader < GraphQL::Batch::Loader
      def initialize(model, unscoped: false)
        @unscoped = unscoped
        @model = model
      end

      def perform(ids)
        if @unscoped
          @model.unscoped { @model.where(:id.in => ids).each { |record| fulfill(record.id.to_s, record) } }
        else
          @model.where(:id.in => ids).each { |record| fulfill(record.id.to_s, record) }
        end
        ids.each { |id| fulfill(id, nil) unless fulfilled?(id) }
      end
    end
  end
end
