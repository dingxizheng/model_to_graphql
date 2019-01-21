# frozen_string_literal: true

module ModelToGraphql
  module Loaders

    class RecordLoader < GraphQL::Batch::Loader
      def initialize(model)
        @model = model
      end

      def perform(ids)
        puts "HELLO #{ ids }"
        @model.where(:id.in => ids).each { |record| fulfill(record.id.to_s, record) }
        ids.each { |id| fulfill(id, nil) unless fulfilled?(id) }
      end
    end
  end
end
