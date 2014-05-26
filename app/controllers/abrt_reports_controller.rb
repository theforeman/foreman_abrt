class AbrtReportsController < ApplicationController

  def action_permission
    case params[:action]
      when 'json'
        :view
      when 'forward'
        :forward
      else
        super
    end
  end

  # GET /abrt_reports
  def index
    #TODO: permissions
    @abrt_reports = resource_base.search_for(params[:search], :order => params[:order]).paginate(:page => params[:page], :per_page => params[:per_page]).includes(:host)
  end

  # GET /abrt_reports/42
  def show
    @abrt_report = resource_base.find(params[:id])
  end

  # DELETE /abrt_reports/42
  def destroy
    @abrt_report = resource_base.find(params[:id])
    if @abrt_report.destroy
      notice _("Successfully deleted bug report.")
    else
      error @abrt_reports.errors.full_messages.join("<br/>")
    end
    redirect_to abrt_reports_url
  end

  # GET /abrt_reports/42/json
  def json
    @abrt_report = resource_base.find(params[:id])
    render :json => JSON.parse(@abrt_report.json)
  end

  # POST /abrt_reports/42/forward
  def forward
    #XXX auditable?
    @abrt_report = resource_base.find(params[:id])
    redirect_to abrt_report_url(@abrt_report)

    begin
      response = @abrt_report.forward
    rescue => e
      error _("Server rejected our report: #{e.message}") and return
    end

    begin
      @abrt_report.add_response response
    rescue => e
      error _("Cannot process server response: #{e.message}") and return
    end

    notice _("Report successfully forwarded")
  end
end
