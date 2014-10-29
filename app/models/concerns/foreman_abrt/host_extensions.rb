module ForemanAbrt::HostExtensions
  extend ActiveSupport::Concern

  included do
    has_many :abrt_reports, :dependent => :destroy, :foreign_key => "host_id"

    scoped_search :in => :abrt_reports, :on => :reason,           :complete_value => true, :rename => :abrt_report_reason
    scoped_search :in => :abrt_reports, :on => :count,            :complete_value => true, :rename => :abrt_report_count,     :only_explicit => true
    scoped_search :in => :abrt_reports, :on => :reported_at,      :complete_value => true, :rename => :abrt_report_reported,  :only_explicit => true

    scoped_search :in => :abrt_reports, :on => :forwarded_at,     :complete_value => true, :rename => :abrt_report_forwarded, :only_explicit => true
    scoped_search :in => :abrt_reports, :on => :response_known,   :complete_value => true, :rename => :abrt_report_known,     :only_explicit => true
    scoped_search :in => :abrt_reports, :on => :response_message, :complete_value => true, :rename => :abrt_report_response
  end

  def recent_abrt_reports
    abrt_reports.where(:reported_at => (Time.now - 1.week)..Time.now).limit(10)
  end
end
