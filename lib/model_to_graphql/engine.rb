# frozen_string_literal: true

require "contracts"

module ModelToGraphql
  class Engine
    include Contracts::Core
    C = Contracts

    Contract String => nil
    def scan_models(model_path)
      # Load all models
      Dir[File.join(model_path, "*.rb")].each do |file|
        require file
      end
    end

    Contract String => nil
    def scan_model_definitions(model_def_path)
      # Load all models
      Dir[File.join(model_def_path, "*.rb")].each do |file|
        require file
      end
    end

    Contract Class => Class
    def find_model_def(model)
      equals = model.method(:==)
      ModelDefinition.definitions.select(&equals)&.first
    end
  end
end
