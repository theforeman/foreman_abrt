class AbrtReportsController < ApplicationController

  # TODO: #create should probably be moved into separate API controller
  include Foreman::Controller::SmartProxyAuth
  add_puppetmaster_filters :create

  def action_permission
    case params[:action]
      when 'json'
        :view
      else
        super
    end
  end

  # POST /abrt_reports
  def create
    # receive json
    if AbrtReport.import(params[:abrt_report])
      render :json => { "status" => "OK" }
    else
      render :json => { "status" => "error" }, :status => 500
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
end
