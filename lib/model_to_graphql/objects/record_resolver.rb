# frozen_string_literal: true

module Objects
  module RecordResolver
    def self.[](model)
      const_get(model.name)
    end

    def self.const_missing(name)
    end
  end
end