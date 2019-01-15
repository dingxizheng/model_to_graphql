# frozen_string_literal: true

require "contracts"
require_relative "../contracts/contracts.rb"
require_relative "../objects/field.rb"
require_relative "../orm/relation_helper.rb"

FIELD = ModelToGraphql::Objects::Field

module ModelToGraphql
  module Definitions
    class ModelDefinition
      include ORM::RelationHelper
      include Contracts::Core

      C = Contracts

      Contract nil => C::ArrayOf[Class]
      def self.definitions
        ModelDefinition.descendants
      end

      Contract MongoidModel => MongoidModel
      def self.define_for_model(model_class)
        raise ArgumentError.new("To graphql definition is turned off for #{model_class}") if model_class.graphql_turned_on?
        @model_class = model_class
      end

      Contract nil => C::Maybe[MongoidModel]
      def self.model
        @model_class
      end

      Contract C::Args[C::Or[String, Symbol]] => C::ArrayOf[String]
      def self.exclude_fields(*fields)
        @exclude_fields = fields.map(&:to_s)
      end

      Contract C::Args[C::Or[String, Symbol]] => C::ArrayOf[String]
      def self.disable_sort_on(*fields)
        @unsortable_fields = fields.map(&:to_s)
      end

      Contract C::Args[C::Or[String, Symbol]] => C::ArrayOf[String]
      def self.disable_filter_on(*fields)
        @unfilterable_fields = fields.map(&:to_s)
      end

      Contract C::Args[C::Or[String, Symbol]] => C::ArrayOf[String]
      def self.disable_edit_on(*fields)
        @uneditable_fields = fields.map(&:to_s)
      end

      Contract C::Args[C::Or[String, Symbol]] => C::ArrayOf[String]
      def self.disable_link_on(*relations)
        @disabled_links = relations.map(&:to_s)
      end

      Contract C::Or[String, Symbol], FIELD::FIELD_OPTION_TYPE, C::Func => C::Any
      def self.field(field_name, **options)
        @defined_fields ||= {}
        @defined_fields[field_name.to_s] = Hash[name: field_name, **options]
      end

      Contract C::Or[String, Symbol], FIELD::FIELD_OPTION_TYPE => C::Any
      def self.field_attribute(field_name, **options)
        # model.fields[field_name.to_s].options.merge!(options)
        @defined_field || {}
        @defined_fields[field_name.to_s] ||= Hash[]
        @defined_fields[field_name.to_s].merge!(options)
      end

      # Merge local defined fields with model fields
      def self.merged_fields
        model_fields = model.nil? ? [] : model.fields
        obj_fields = model_fields.map do |_, field|
                      ModelToGraphql::Objects::Field.new(field)
                    end
                    .select { |f| !@exclude_fields&.include?(f.name.to_s) }

        change_sorable   = ->(f) { @unsortable_fields&.include?(f.name.to_s) && f.sortable = false }
        change_filerable = ->(f) { @unfilterable_fields&.include?(f.name.to_s) && f.filterable = false }
        change_editable  = ->(f) { @uneditable_fields&.include?(f.name.to_s) && f.editable = false }

        obj_fields
          .each(&change_sorable)
          .each(&change_filerable)
          .each(&change_editable)

        custom_fields = (@defined_fields || []).map do |name, field|
            ModelToGraphql::Objects::Field.new(name, field)
          end
          .select { |f| !@exclude_fields&.include?(f.name.f) }

        custom_fields
          .each(&change_sorable)
          .each(&change_filerable)
          .each(&change_editable)

        custom_fields.each do |f|
          existing_field = obj_fields.select { |of| of.name == f.name }&.first
          unless existing_field.nil?
            existing_field.merge!(f)
          else
            obj_fields << f
          end
        end

        # return all fields
        obj_fields
      end

      def self.discover_links(context)
        return [] if model.nil?
        model.reflect_on_all_associations(:belongs_to).each do |relation|
          field relation.name,
            resolver: context.relation_resolver(relation)
        end
        model.reflect_on_all_associations(:has_one).each do |relation|
          field relation.name,
            resolver: context.relation_resolver(relation)
        end
        model.reflect_on_all_associations(:has_many).each do |relation|
          field relation.name,
            resolver: context.relation_resolver(relation)
        end
      end
    end
  end
end
