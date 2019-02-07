# frozen_string_literal: true

require "contracts"
require_relative "../contracts/contracts.rb"
require_relative "../orm/mongoid_settings.rb"

module ModelToGraphql
  module Objects
    class Field
      include Contracts::Core
      C = Contracts

      ALLOWED_TYPES = C::ArrayOf[ModelToGraphql::ORM::MongoidSettings::TYPE_MAPPINGS.values]

      FIELD_OPTION_TYPE = {
        type:        C::Maybe[Class],
        label:       C::Maybe[String],
        element:     C::Maybe[Class],
        sortable:    C::Maybe[C::Bool],
        editable:    C::Maybe[C::Bool],
        filterable:  C::Maybe[C::Bool],
        required:    C::Maybe[C::Bool],
        resolver:    C::Maybe[C::Or[GraphQLResolver, GraphQLResolverPromise]],
        text:        C::Maybe[C::Bool],
        default:     C::Maybe[C::Any],
        # placeholder value should respond_to placeholder? and resolve_value
        placeholder: C::Maybe[C::RespondTo[:"placeholder?", :resolve_value]]
      }.freeze

      # Attributes
      attr_accessor :name, :type, :element, :required,
        :label, :sortable, :editable, :filterable,
        :foreign_key, :foreign_class, :text, :default,
        :resolver

      Contract MongoidIdField => C::Any
      def initialize(field)
        self.name = :id
        self.type = :id
        self.required = false
        self.editable = false
      end

      Contract MongoidStdField => C::Any
      def initialize(field)
        assign_attrs(field.name, field.options.slice(*FIELD_OPTION_TYPE.keys))
      end

      Contract MongoidFKField => C::Any
      def initialize(field)
        self.foreign_key = true

        model_klass = field.options[:klass]
        relation = model_klass.relations.select do |_, rl|
          rl.respond_to?(:foreign_key) && field.name == rl.foreign_key
        end.to_a.first&.last

        klasses = if relation.polymorphic?
                    Mongoid.models.select do |m|
                      m.relations.any? { |_key, model_relation| model_relation.polymorphic? && model_relation.options[:as] == relation.name && model_relation.klass == relation.inverse_class  }
                    end
                  else
                    [relation.klass]
                  end

        self.foreign_class = klasses
        assign_attrs(field.name, field.options.slice(*FIELD_OPTION_TYPE.keys))
        self.type = :object_id
      rescue => e
        pp field
        raise e
      end

      Contract MongoidLocalizedField => C::Any
      def initialize(field)
        assign_attrs(field.name, field.options.slice(*FIELD_OPTION_TYPE.keys))
      end

      Contract String, FIELD_OPTION_TYPE => C::Any
      def initialize(name, **options)
        assign_attrs(name, options)
      end

      def null?
        self.required ? false : true
      end

      def required?
        self.required ? true : false
      end

      Contract String, FIELD_OPTION_TYPE => C::Any
      def assign_attrs(name, **options)
        self.name = name.to_sym
        options.each do |key, val|
          if key.to_s == "type"
            # find_the_cloest_type_symbol
            self.type = find_the_cloest_type_symbol(val)
          elsif key.to_s == "element"
            # ele_key = ModelToGraphql::ORM::MongoidSettings::TYPE_MAPPINGS.select { |_, v| v == val }.to_a.first&.first
            self.element = find_the_cloest_type_symbol(val)
          else
            self.send("#{key}=", val)
          end
        end

        case type
        when :id, :string, :integer, :float, :date, :time, :boolean, :date_time, :symbol
          self.sortable = true unless sortable
        else
          self.sortable = false
        end

        case type
        when :id, :string, :integer, :float, :date, :time, :boolean, :date_time, :array, :symbol
          self.filterable = true unless filterable
        else
          self.filterable = false
        end

        if text
          self.sortable = false
        end
      end

      def find_the_cloest_type_symbol(type)
        type_found = Object
        type_symbol = :string
        ModelToGraphql::ORM::MongoidSettings::TYPE_MAPPINGS.each do |sym, v|
          if v >= type && type_found > v
            type_found = v
            type_symbol = sym
          end
        end
        type_symbol
      end

      Contract Field => Field
      def merge!(field)
        FIELD_OPTION_TYPE.keys.each do |key|
          self.send("#{key}=", field.send(key)) unless field.send(key).nil?
        end
        self
      end
    end
  end
end
