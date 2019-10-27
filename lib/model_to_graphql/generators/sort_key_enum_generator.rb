# frozen_string_literal: true

module ModelToGraphql
  module Generators
    class SortKeyEnumGenerator < GraphQL::Schema::Enum
      include Contracts::Core
      C = Contracts

      Contract String, C::ArrayOf[ModelToGraphql::Objects::Field] => C::Any
      def self.to_graphql_enum(name, fields)
        Class.new(SortKeyEnumGenerator) do
          graphql_name name
          define_enums fields
          def self.name
            name
          end
        end
      end

      Contract C::ArrayOf[ModelToGraphql::Objects::Field] => C::Any
      def self.define_enums(fields)
        fields.select { |f| f.sortable }
              .each(&method(:make_enum))
      end

      def self.make_enum(field)
        value("#{field.name}_asc", "Sort by #{field.name} in ascending order")
        value("#{field.name}_desc", "Sort by #{field.name} in desecnding order")
      end
    end
  end
end
