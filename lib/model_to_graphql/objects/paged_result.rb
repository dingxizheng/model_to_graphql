# frozen_string_literal: true

module ModelToGraphql
  module Objects
    module PagedResult
      def self.[](return_type)
        const_name = return_type.graphql_name
        if self.const_defined?("P#{const_name}")
          ModelToGraphql.logger.debug "ModelToGQL | get paged result for type #{const_name}"
          self.const_get("P#{const_name}")
        else
          ModelToGraphql.logger.debug "ModelToGQL | create paged result for type #{const_name}"
          klass = Class.new(GraphQL::Schema::Object) do
            description "Paged result"
            graphql_name "#{const_name}PagedResult"

            field :total, Integer, null: false
            field :page,  Integer, null: false
            field :list,  [return_type], null: true

            def total
              object&.list&.count
            end
          end

          self.const_set("P#{const_name}", klass)
          klass
        end
      end

      def self.remove_all_constants
        self.constants.each do |c|
          ModelToGraphql::Objects::PagedResult.send(:remove_const, c)
        end
      end
    end
  end
end