# frozen_string_literal: true

module Objects
  module QueryResolver
    def self.[](model, custom_name = nil, **opts)
      const_get(model.name)
    end

    def self.const_missing(name)
    end
  end
end