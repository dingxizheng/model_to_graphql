# frozen_string_literal: true

module ModelToGraphql
  module Types
    class PagedResultType < GraphQL::Schema::Object
      def self.[](return_type, name = nil)
        Class.new(GraphQL::Schema::Object) do
          description "Paged result"
          graphql_name "#{ name || return_type.graphql_name}PagedResult"

          field :total, Integer, null: false
          field :page,  Integer, null: false
          field :list,  [return_type], null: true

          def total
            object&.list&.count
          end
        end
      end

      def inspect
        "#<#{graphql_name}>"
      end
    end
  end
end
