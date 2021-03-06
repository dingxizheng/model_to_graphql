# frozen_string_literal: true

FIELD = ModelToGraphql::Objects::Field

module ModelToGraphql
  module Definitions
    class ModelDefinition

      class << self
        attr_accessor :filters, :raw_fields
      end

      def self.definitions
        ModelToGraphql::Definitions::ModelDefinition.descendants
      end

      def self.define_for_model(model_class)
        @model_class = model_class.name
      end

      def self.model
        @model_class.constantize
      end

      def self.model_name
        @model_class
      end

      def self.exclude_fields(*fields)
        @exclude_fields = fields.map(&:to_s)
      end

      def self.disable_sort_on(*fields)
        @unsortable_fields = fields.map(&:to_s)
      end

      def self.disable_filter_on(*fields)
        @unfilterable_fields = fields.map(&:to_s)
      end

      def self.disable_edit_on(*fields)
        @uneditable_fields = fields.map(&:to_s)
      end

      def self.disable_link_on(*relations)
        @disabled_links = relations.map(&:to_s)
      end

      def self.field(field_name, **options)
        @defined_fields ||= {}
        @defined_fields[field_name.to_s] = Hash[name: field_name, **options]
      end

      def self.field_attribute(field_name, **options)
        # model.fields[field_name.to_s].options.merge!(options)
        @defined_field || {}
        @defined_fields[field_name.to_s] ||= Hash[]
        @defined_fields[field_name.to_s].merge!(options)
      end

      # Merge local defined fields with model fields
      def self.merged_fields
        return @merged_fields unless @merged_fields.nil?
        model_fields = model.nil? ? [] : model.fields
        obj_fields = model_fields
                      .select { |_, field| field.options[:type] != BSON::Binary }
                      .map    { |_, field| ModelToGraphql::Objects::Field.new(field) }
                      .select { |f| !@exclude_fields&.include?(f.name.to_s) }

        change_sorable   = ->(f) { @unsortable_fields&.include?(f.name.to_s)   && f.sortable = false }
        change_filerable = ->(f) { @unfilterable_fields&.include?(f.name.to_s) && f.filterable = false }
        change_editable  = ->(f) { @uneditable_fields&.include?(f.name.to_s)   && f.editable = false }

        obj_fields
          .each(&change_sorable)
          .each(&change_filerable)
          .each(&change_editable)

        custom_fields = (@defined_fields || [])
          .map    { |name, field| ModelToGraphql::Objects::Field.new(name, field) }
          .select { |f| !@exclude_fields&.include?(f.name) }

        if model.has_child_model? && model.fields["_type"].nil?
          custom_fields << ModelToGraphql::Objects::Field.new("_type", type: String)
        end

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
        @merged_fields = obj_fields
      end

      def self.scan_relations
        return [] if model.nil?
        self.scan_relations_of(:belongs_to)
        self.scan_relations_of(:has_one)
        self.scan_relations_of(:has_many)
        self.scan_relations_of(:has_and_belongs_to_many)
        self.scan_relations_of(:embeds_one)
        self.scan_relations_of(:embeds_many)
      end

      def self.scan_relations_of(link_type)
        model.reflect_on_all_associations(link_type).each do |relation|
          # field relation.name, resolver: RelationResolver.of(relation).resolve
          self.field(relation.name, resolver: relation)
        end
      end

      def self.filter(name, input_type, handler: nil)
        self.filters ||= []
        self.filters << { name: name.to_sym, input_type: input_type, handler: handler }
      end

      def self.raw_field(name, type, **options, &block)
        self.raw_fields ||= []
        if block_given?
          self.raw_fields << { name: name.to_sym, type: type, options: options, block: block }
        else
          self.raw_fields << { name: name.to_sym, type: type, options: options }
        end
      end
    end
  end
end
