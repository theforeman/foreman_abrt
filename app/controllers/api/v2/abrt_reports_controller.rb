module Api
  module V2
    class AbrtReportsController < V2::BaseController
      include Api::Version2
      include Foreman::Controller::SmartProxyAuth
      include AbrtReportsHelper

      add_puppetmaster_filters :create

      def create
        begin
          abrt_reports = AbrtReport.import(params[:abrt_report])
        rescue => e
          logger.error "Failed to import ABRT report: #{e.message}"
          logger.debug e.backtrace.join("\n")
          render :json => { 'message' => e.message }, :status => :unprocessable_entity
          return
        end

        if abrt_reports.count == 0
          render :json => { 'message' => 'Failed to import any report'}, :status => :unprocessable_entity
          return
        end

        if Setting[:abrt_automatically_forward]
          abrt_reports.each do |report|
            begin
              response = send_to_abrt_server report
              report.add_response response
            rescue => e
              logger.error "Failed to forward ABRT report: #{e.message}"
            end
          end
        end

        # Do not report forwarding error to the proxy, we can manually resend
        # it later and the proxy probably can't do anything about it anyway.
        render :json => { 'message' => 'OK' }
      end

    end
  end
end
