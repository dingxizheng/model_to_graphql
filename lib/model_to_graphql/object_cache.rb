# frozen_string_literal: true

module ModelToGraphql
  module ObjectCache

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def cache(name, object)
        ModelToGraphql.logger.debug "ModelToGQL | Caching #{name} for #{self.name}"
        @_cache ||= {}
        @_cache[name] = object
      end

      def get_object(name)
        ModelToGraphql.logger.debug "ModelToGQL | Looking for #{self.name} for: #{name}"
        @_cache ||= {}
        @_cache[name]
      end

      def clear
        @_cache = {}
      end
    end
  end
end
