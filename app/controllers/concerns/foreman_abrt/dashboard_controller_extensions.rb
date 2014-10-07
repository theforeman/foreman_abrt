module ForemanAbrt::DashboardControllerExtensions
  extend ActiveSupport::Concern

  included do
    before_filter :prefetch_abrt_data, :only => :index
  end

  def prefetch_abrt_data
    @abrt_reports = AbrtReport.authorized(:view_abrt_reports)
  end
end
