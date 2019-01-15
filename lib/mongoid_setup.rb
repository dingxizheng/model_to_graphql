# frozen_string_literal: true

# Custom mognoid field optios

# Element option is used to indicate the element type of an array field
# ==== Examples
#   field :tags, type: Array, element: String
Mongoid::Fields.option :element do |model, field, _|
end

# Required option is a short hand option for validates_presence_of
# ==== Examples
#   field :name, type: String, required: true
Mongoid::Fields.option :required do |model, field, _|
  model.validates_presence_of :"#{field.name}"
end

# Text option is used to indicate that the string field is long
# ==== Examples
#   field :comment, type: String, text: true
Mongoid::Fields.option :text do |model, field, _|
end

# Label option is used for using a different name for current field
# ==== Examples
#   field :comment, type: String, label: "Use comment"
Mongoid::Fields.option :label do |model, field, _|
end

# This field is used to indicate which field should be shown if current model is show in the table of other tables.
# ==== Examples
#   field :comment, type: String, label: "Use comment"
Mongoid::Fields.option :reference do |model, field, _|
end

# Indicates if the field is unfilterable
Mongoid::Fields.option :filterable do |model, field, _|
end

# Indicates if the field is editable
Mongoid::Fields.option :editable do |model, field, _|
end

# Indicates if the field is sortable
Mongoid::Fields.option :sortable do |model, field, _|
end

# Add option method to Mongoid::Document
module Mongoid
  module Document
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Where turn on graphql for the current model
      def turn_on_graphql(boolean = true)
        @turn_on_graphql = boolean
      end

      def graphql_turned_on?
        reutrn false if embedded_model?
        return false if @turn_on_graphql.nil?
        @turn_on_graphql
      end

      # Check if current model is embedded in other models
      def embedded_model?
        reflect_on_all_associations(:embedded_in).size > 0
      end
    end
  end
end
