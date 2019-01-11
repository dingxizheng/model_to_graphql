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
        def mount_mutations(engine)
          engine.graphql_objects.each do |meta|
            mutation_name = :"add_#{meta[:model].name.underscore.downcase}"
            field mutation_name, mutation: meta[:graphql_mutation]
          end
        end

        ##
        # Mount generated graphql queries from specified engine
        #
        # === Parameters
        # [engine (Engine)] The model engine
        def mount_queries(engine)
          engine.graphql_objects.each do |meta|
            field meta[:model].name.underscore.pluralize,
              resolver: meta[:graphql_model_resolver]

            field meta[:model].name.underscore.downcase,
              resolver: meta[:graphql_record_resolver]
          end
        end

      end
    end
  end
end