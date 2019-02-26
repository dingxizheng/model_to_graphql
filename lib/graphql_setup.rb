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
          engine.initialized.then do |parsed_models|
            parsed_models
              .select { |m| !m.model.embedded? }
              .each do |model_meta|
                model_name = engine.model_name(model_meta.model)
                # Add query field
                field model_name.underscore.pluralize, resolver: model_meta.model_resolver do
                  guard_proc = engine.config[:authorize_action]
                  if !guard_proc.nil? && guard_proc.is_a?(Proc)
                    guard(-> (obj, args, ctx) {
                      guard_proc.call(obj, args, ctx, :query_model, model_meta.model)
                    })
                  end
                end

                # Add single query field
                field model_name.underscore.downcase, resolver: model_meta.single_resolver do
                  guard_proc = engine.config[:authorize_action]
                  if !guard_proc.nil? && guard_proc.is_a?(Proc)
                    guard(-> (obj, args, ctx) {
                      guard_proc.call(obj, args, ctx, :view_model, model_meta.model)
                    })
                  end
                end

                if model_meta.query_keys
                  field "#{model_name.underscore.downcase}_query_keys", [model_meta.query_keys], null: true
                  define_method("#{model_name.underscore.downcase}_query_keys") do
                    model_meta.query_keys.map { |f| f.values.keys }
                  end
                end
              end
          end
          .then(nil, proc { |reason|
            puts "Failed to mount_queries, error: #{reason}"
            raise reason
          })
        end
      end
    end
  end
end
