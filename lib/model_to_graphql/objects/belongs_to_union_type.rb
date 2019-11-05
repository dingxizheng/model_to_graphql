# frozen_string_literal: true
module ModelToGraphql
  module Objects
    module BelongsToUnionType
      def self.[](relation)
        "#{self.name}::#{relation.name.capitalize}".constantize
      end

      def self.const_missing(name)
        return self.const_get(name) if self.self_const_defined?(name)

        relation_name = name.to_s.downcase.to_sym
        graphql_types = Mongoid.models.select do |m|
                          m.relations.any? { |_, field| field.options[:as] == relation_name }
                        end.map do |m|
                          ModelToGraphql::Objects::Type[m]
                        end

        type_name = "Possible#{relation_name.to_s.capitalize}Type"
        union_type = Class.new(GraphQL::Schema::Union) do
                        graphql_name(type_name)
                        possible_types(*graphql_types)
                        def self.resolve_type(obj, _ctx)
                          ModelToGraphql::Objects::Type[obj.class]
                        rescue => _
                          fail "Couldn't find the return type of object #{obj} when its class it's #{obj.class}"
                        end
                      end

        self.const_set(name, union_type)
      end

      def self.self_const_defined?(name)
        if self.const_defined?(name)
          c = self.const_get(name)
          c.name.start_with?(self.name)
        else
          false
        end
      end

      def self.remove_all_constants
        self.constants.each do |c|
          self.send(:remove_const, c)
        end
      end
    end
  end
end