class AbrtReportsController < ApplicationController

  def action_permission
    case params[:action]
      when 'json'
        :view
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
end
