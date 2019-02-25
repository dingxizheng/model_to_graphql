# frozen_string_literal: true

module ModelToGraphql
  module ObjectCache

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def cache(name, object)
        @_cache ||= {}
        @_cache[name] = object
      end

      def get_object(name)
        @_cache ||= {}
        @_cache[name]
      end

      def clear
        @_cache = {}
      end
    end
  end
end
