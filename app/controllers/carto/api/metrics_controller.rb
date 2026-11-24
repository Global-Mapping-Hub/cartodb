module Carto
  module Api
    class MetricsController < ::Api::ApplicationController
      ssl_required :create

      skip_before_filter :api_authorization_required

      before_filter :load_event, only: :create

      rescue_from Carto::LoadError,
                  Carto::UnauthorizedError,
                  Carto::UnprocesableEntityError, with: :rescue_from_carto_error

      def create
        @event.report!

        render json: Hash.new, status: :created
      end

      private

      def load_event
        event_name = params[:name].to_s
        raise Carto::UnprocesableEntityError.new('name not provided') if event_name.empty?

        properties = params[:properties].presence || {}
        reporter_id = current_viewer.try(:id)
        require_dependency 'carto/tracking/events'

        @event = Carto::Tracking::Events::SegmentEvent.build(event_name, reporter_id, properties)
        @event ||= named_event(event_name, reporter_id, properties)
        raise Carto::LoadError.new("Event not found: #{event_name}") unless @event
      end

      def named_event(event_name, reporter_id, properties)
        [event_name, event_name.tr('-', '_')].map(&:camelize).uniq.each do |candidate|
          event_class = "Carto::Tracking::Events::#{candidate}".safe_constantize
          return event_class.new(reporter_id, properties) if event_class
        end
        nil
      end
    end
  end
end
