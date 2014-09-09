class AbrtReportsController < ApplicationController
  include Foreman::Controller::AutoCompleteSearch
  before_filter :setup_search_options, :only => :index
  before_filter :find_by_id, :only => [:show, :destroy, :json, :forward]

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
    @abrt_reports = resource_base.search_for(params[:search], :order => params[:order]).paginate(:page => params[:page], :per_page => params[:per_page]).includes(:host)
  end

  # GET /abrt_reports/42
  def show
  end

  # DELETE /abrt_reports/42
  def destroy
    if @abrt_report.destroy
      notice _("Successfully deleted bug report.")
    else
      error @abrt_reports.errors.full_messages.join("<br/>")
    end
    redirect_to abrt_reports_url
  end

  # GET /abrt_reports/42/json
  def json
    render :json => JSON.parse(@abrt_report.json)
  end

  # POST /abrt_reports/42/forward
  def forward
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

  private

  def find_by_id
    @abrt_report = resource_base.find(params[:id])
  end
end
