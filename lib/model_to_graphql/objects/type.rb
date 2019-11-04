# frozen_string_literal: true

module ModelToGraphql
  module Objects
    module Type
      def self.[](model)
        case model
        when String, Symbol
          "#{self.name}::#{normalize_name(model)}".constantize
        else
          "#{self.name}::#{normalize_name(model.name)}".constantize
        end
      end

      def self.const_missing(name)
        return_type = ModelToGraphql::Objects::Helper.make_return_type(denormalize(name))
        self.const_set(name, return_type)
      end

      def self.remove_all_constants
        self.constants.each do |c|
          ModelToGraphql::Objects::Type.send(:remove_const, c)
        end
      end

      def self.normalize_name(name)
        name.to_s.gsub("::", "__")
      end

      def self.denormalize(name)
        name.to_s.gsub("__", "::")
      end
    end
  end
end