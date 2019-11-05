# frozen_string_literal: true
module ModelToGraphql
  module Objects
    module ModelDefinition
      def self.[](model)
        case model
        when String, Symbol
          "#{self.name}::#{normalize_name(model)}".constantize
        else
          "#{self.name}::#{normalize_name(model.name)}".constantize
        end
      end

      def self.const_missing(name)
        return self.const_get(name) if self.self_const_defined?(name)
        cnst = ModelToGraphql::Objects::Helper.make_model_definition(denormalize(name))
        self.const_set(name, cnst)
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

      def self.normalize_name(name)
        name.to_s.gsub("::", "__")
      end

      def self.denormalize(name)
        name.to_s.gsub("__", "::")
      end
    end
  end
end