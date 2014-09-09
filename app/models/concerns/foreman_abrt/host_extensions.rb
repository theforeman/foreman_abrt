module ForemanAbrt::HostExtensions
  extend ActiveSupport::Concern

  included do
    has_many :abrt_reports, :dependent => :destroy, :foreign_key => "host_id"
  end

  def recent_abrt_reports
    abrt_reports.where(:reported_at => (Time.now - 1.month)..Time.now)
  end
end
