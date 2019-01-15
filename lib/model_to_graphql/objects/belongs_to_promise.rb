# frozen_string_literal: true

require "promise.rb"

class BelongsToPromise < Promise
  attr_accessor :relation, :context

  def initialize(relation, context)
    @relation = relation
    @context = context
  end

  def resolve
  end
end
