# frozen_string_literal: true

module ModelToGraphql
  module Generators
    class SortKeyEnumGenerator < GraphQL::Schema::Enum
      include Contracts::Core
      C = Contracts

      Contract String, C::ArrayOf[ModelToGraphql::Objects::Field] => C::Any
      def self.build(gl_name, fields)
        ModelToGraphql.logger.debug "ModelToGQL | Generating graphql type #{gl_name} ..."
        klass = Class.new(SortKeyEnumGenerator) do
          graphql_name gl_name
          define_enums fields
          def self.name
            gl_name
          end
        end
        klass
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
