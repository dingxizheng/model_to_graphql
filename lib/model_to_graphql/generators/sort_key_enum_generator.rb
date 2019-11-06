# frozen_string_literal: true

module ModelToGraphql
  module Generators
    class SortKeyEnumGenerator < GraphQL::Schema::Enum

      def self.build(gl_name, fields)
        ModelToGraphql.logger.debug "ModelToGQL | Generating graphql type #{gl_name} ..."
        Class.new(SortKeyEnumGenerator) do
          graphql_name(gl_name)
          define_enums(fields)
          def self.name
            gl_name
          end
        end
      end

      def self.define_enums(fields)
        fields.select { |f| f.sortable }
              .each(&method(:make_enum))
      end

      def self.make_enum(field)
        value("#{field.name}_asc", "Sort by #{field.name} in ascending order")
        value("#{field.name}_desc", "Sort by #{field.name} in desecnding order")
      end

      def self.inspect
        "#<#{name}>"
      end
    end
  end
end
