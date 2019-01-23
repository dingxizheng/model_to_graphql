# frozen_string_literal: true

module ModelToGraphql
  module Types
    class PagedResultType < GraphQL::Schema::Object
      def self.[](return_type, name = nil)
        Class.new(GraphQL::Schema::Object) do
          description "Paged result"
          graphql_name "#{ name || return_type.name}PagedResult"
          field :total, Integer, null: false
          field :page,  Integer, null: false
          field :list,  [return_type], null: true
        end
      end
    end
  end
end
