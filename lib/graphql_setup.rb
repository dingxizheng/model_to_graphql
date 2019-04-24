# frozen_string_literal: true

module GraphQL
  class Schema
    class Object
      class << self
        ##
        # Mount generated graphql mutations from specified engine
        #
        # === Parameters
        # [engine (Engine)] The model engine
        # def mount_mutations(engine)
        #   engine.graphql_objects.each do |meta|
        #     mutation_name = :"add_#{meta[:model].name.underscore.downcase}"
        #     field mutation_name, mutation: meta[:graphql_mutation]
        #   end
        # end

        ##
        # Mount generated graphql queries from specified engine
        #
        # === Parameters
        # [engine (Engine)] The model engine
        def mount_queries(engine)
          raise ArgumentError, "engine must be a ModelToGraphql::Engine instance" unless engine.is_a? ModelToGraphql::Engine

          engine.top_level_fields.each do |model_name|
            model = model_name.constantize
            ModelToGraphql.logger.debug "ModelToGQL | Add top level fields for model: #{ model.name }"

            field model_name(model_name).underscore.pluralize, resolver: ModelToGraphql::FieldHolders::QueryResolver[model] do
              guard_proc = engine.config[:authorize_action]
              if !guard_proc.nil? && guard_proc.is_a?(Proc)
                guard(-> (obj, args, ctx) {
                  guard_proc.call(obj, args, ctx, :query_model, model)
                })
              end
            end

            field model_name(model_name).underscore.downcase,  resolver: ModelToGraphql::FieldHolders::SingleResolver[model] do
              guard_proc = engine.config[:authorize_action]
              if !guard_proc.nil? && guard_proc.is_a?(Proc)
                guard(-> (obj, args, ctx) {
                  guard_proc.call(obj, args, ctx, :view_model, model)
                })
              end
            end

            field "#{model_name(model_name).underscore.downcase}_query_keys", resolver: ModelToGraphql::FieldHolders::QueryKeyResolver[model]
          end
        end

        def model_name(model)
          model.delete("::")
        end
      end
    end
  end
end
