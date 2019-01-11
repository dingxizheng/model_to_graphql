# frozen_string_literal: true

require "contracts"
require_relative "../contracts/contracts.rb"

module ModelToGraphql
  module Objects
    class Link
      include Contracts::Core
      C = Contracts

      # Attributes
      attr_accessor :type, :model_class

      Contract MongoidModel => C::Any
      def initialize(model)
      end

      Contract Hash => C::Any
      def initialize(model)
      end
    end
  end
end
