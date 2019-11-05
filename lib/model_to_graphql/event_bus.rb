# frozen_string_literal: true

module ModelToGraphql
  class EventBus
    class << self
      def clear
        @ready_models = []
        @subscribers  = {}
      end

      def broadcast(model_name)
        ModelToGraphql.logger.debug "ModelToGQL | type #{model_name} is ready!"
        @ready_models ||= []
        @ready_models << model_name
        notify_subscribers
      end

      def on_ready(*model_names, &block)
        unless fire_callback(*model_names, block)
          @subscribers ||= {}
          @subscribers[block.object_id] = { models: model_names, block: block, fired: false }
        end
      end

      def notify_subscribers
        @subscribers ||= {}
        @subscribers.keys.each do |key|
          data = @subscribers[key]
          if !data[:fired] && fire_callback(*data[:models], data[:block])
            @subscribers[key] = data.merge(fired: true)
          end
        end
      end

      def fire_callback(*models, callback)
        @ready_models ||= []
        if models.all? { |m| @ready_models.include?(m) }
          callback.call
          true
        else
          false
        end
      end

      def fulfill_unfired_requests
        @subscribers ||= {}
        @subscribers.keys.each do |key|
          data = @subscribers[key]
          if !data[:fired]
            data[:models].each do |name|
              ModelToGraphql::Objects::Type[name]
            end
          end
        end
      end
    end
  end
end
