# frozen_string_literal: true

FIELD = ModelToGraphql::Objects::Field

module ModelToGraphql
  module Definitions
    class ModelDefinition
      include Contracts::Core
      C = Contracts

      @@descendant_classes = []
      @@descendant_classes_map = {}

      class << self
        attr_accessor :filters, :raw_fields
        # def inherited(child_class)
        #   @@descendant_classes ||= []
        #   @@descendant_classes << child_class
        # end

        # def clear_descendants
        #   @@descendant_classes = []
        #   @@descendant_classes_map = {}
        # end
      end

      Contract nil => C::ArrayOf[Class]
      def self.definitions
        ModelDefinition.descendants
      end

      Contract MongoidModel => C::Any
      def self.define_for_model(model_class)
        @model_class = model_class.name
      end

      Contract nil => C::Maybe[MongoidModel]
      def self.model
        @model_class.constantize
      end

      def self.model_name
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
        obj_fields
      end

      def self.discover_links(context)
        return [] if model.nil?
        discover_links_of :belongs_to,  context: context
        discover_links_of :has_one,     context: context
        discover_links_of :has_many,    context: context
        discover_links_of :has_and_belongs_to_many,    context: context
        discover_links_of :embeds_one,  context: context
        discover_links_of :embeds_many, context: context
      end

      def self.discover_links_of(link_type, context:)
        model.reflect_on_all_associations(link_type).each do |relation|
          field relation.name, resolver: context.relation_resolver(relation)
        end
      end

      # Define a custom filter
      Contract C::Or[String, Symbol], C::Or[C::ArrayOf[C::Any], Class], { handler: Proc } => C::Any
      def self.filter(name, input_type, handler: nil)
        self.filters ||= []
        self.filters << { name: name.to_sym, input_type: input_type, handler: handler }
      end

      # Define a direct graphql field
      Contract C::Or[String, Symbol], C::Maybe[Class], Hash, Proc => C::Any
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
