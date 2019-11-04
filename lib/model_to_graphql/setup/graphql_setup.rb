# frozen_string_literal: true

module ModelToGraphql
  module Setup
    module GraphqlSetup
      module ClassMethods
        def mount_queries
          top_level_fields = ModelToGraphql.query_fields
          top_level_fields.each do |model_name|
            model = model_name.constantize
            ModelToGraphql.logger.debug "ModelToGQL | Add top level fields for model: #{ model.name }"

            # ModelToGraphql::Objects::Resolver[model, type: :query]
            field model_name(model_name).underscore.pluralize, extras: [:path, :lookahead], resolver: ModelToGraphql::Objects::QueryResolver[model] do
              guard_proc = ModelToGraphql.config_options[:authorize_action]
              if !guard_proc.nil? && guard_proc.is_a?(Proc)
                guard(-> (obj, args, ctx) {
                  guard_proc.call(obj, args, ctx, :query_model, model)
                })
              end
            end

            field model_name(model_name).underscore.downcase, extras: [:path, :lookahead], resolver: ModelToGraphql::Objects::RecordResolver[model] do
              guard_proc = ModelToGraphql.config_options[:authorize_action]
              if !guard_proc.nil? && guard_proc.is_a?(Proc)
                guard(-> (obj, args, ctx) {
                  guard_proc.call(obj, args, ctx, :view_model, model)
                })
              end
            end

            field "#{model_name(model_name).underscore.downcase}_query_keys", resolver: ModelToGraphql::Objects::QueryKey[model]
          end
        end

        def model_name(model)
          model.delete("::")
        end
      end

      def self.prepended(base)
        class << base
          prepend ClassMethods
        end
      end
    end
  end
end

GraphQL::Schema::Object.prepend ModelToGraphql::Setup::GraphqlSetup
