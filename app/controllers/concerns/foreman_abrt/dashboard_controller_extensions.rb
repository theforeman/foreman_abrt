module ForemanAbrt::DashboardControllerExtensions
  extend ActiveSupport::Concern

  included do
    before_filter :prefetch_abrt_data, :only => :index
  end

  def prefetch_abrt_data
    # fetch reports from last 24 hours
    @abrt_reports = AbrtReport.authorized(:view_abrt_reports).where(:created_at => (Time.now - 24.hours)..Time.now).search_for(params[:search])
  end
end
