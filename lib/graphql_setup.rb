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
                field model_meta.model.name.underscore.pluralize,
                  resolver: model_meta.model_resolver

                field model_meta.model.name.underscore.downcase,
                  resolver: model_meta.single_resolver

                if model_meta.query_keys
                  field "#{model_meta.model.name.underscore.downcase}_query_keys", [model_meta.query_keys], null: true,
                    resolve: -> () { model_meta.query_keys.map { |f| f.values.keys } }
                end
              end
          end
        end
      end
    end
  end
end