class AbrtReportResponseDestination < ActiveRecord::Base
  include Authorizable

  belongs_to :abrt_report
end
