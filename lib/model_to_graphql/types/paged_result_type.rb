# frozen_string_literal: true

module ModelToGraphql
  module Types
    class PagedResultType < GraphQL::Schema::Object
      def self.[](return_type, name = nil)
        ModelToGraphql::Objects::PagedResult[return_type]
      end
    end
  end
end
