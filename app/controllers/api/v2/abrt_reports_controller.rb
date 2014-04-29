module Api
  module V2
    class AbrtReportsController < V2::BaseController
      include Api::Version2
      include Foreman::Controller::SmartProxyAuth

      add_puppetmaster_filters :create

      def create
        begin
          AbrtReport.import(params[:abrt_report])
        rescue => e
          logger.error "Failed to import ABRT report: #{e.message}"
          logger.debug e.backtrace.join("\n")
          render :json => { "message" => e.message }, :status => :unprocessable_entity
        else
          render :json => { "message" => "OK" }
        end
      end

    end
  end
end
