# frozen_string_literal: true

require "contracts"
require "promise.rb"
require "./objects/type_promise.rb"
require "./objects/belongs_to_promise.rb"

module ModelToGraphql
  class Engine
    include Contracts::Core
    C = Contracts

    @promises = []

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

    def bootstrap
      Mongoid.models.each do |model|
        model_def = find_model_def(model) || create_model_def(model)
        model_def.discover_links(self)
        model_def.merged_fields
      end
    end

    def make_type(fields)
    end

    def make_query_type(fields)
    end

    def make_mutation()
    end

    def make_filter_type()
    end

    Contract Class => Class
    def find_model_def(model)
      equals = model.method(:==)
      ModelDefinition.definitions.select(&equals)&.first
    end

    Contract Class => Class
    def create_model_def(model)
      Class.new(ModelDefinition) do
        define_for_model model
      end
    end

    def relation_resolver(relation)
      promise = RelationResolverPromise.new(relation, self)
      @promises << promise
      promise
    end
  end
end
