# frozen_string_literal: true

require "contracts"
require_relative "../contracts/contracts.rb"

module ModelToGraphql
  module Objects
    class Model
      # Attributes
      include Contracts::Core
      C = Contracts

      MODEL_OPTION_TYPE = {
        type: C::Any,
        query_type: C::Any,
        model_resolver: C::Any,
        single_resolver: C::Any
      }.freeze

      ALLOWED_ATTRIBUTES = [:type, :query_type, :model_resolver, :single_resolver].freeze
      attr_accessor *ALLOWED_ATTRIBUTES
      attr_accessor :model

      Contract MongoidModel, MODEL_OPTION_TYPE => C::Any
      def initialize(model, **attrs)
        @model = model
        attrs.slice(*ALLOWED_ATTRIBUTES).each do |key, val|
          send("#{key}=", val)
        end
      end
    end
  end
end
