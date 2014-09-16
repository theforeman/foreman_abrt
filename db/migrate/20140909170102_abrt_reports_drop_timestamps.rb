class AbrtReportsDropTimestamps < ActiveRecord::Migration
  def change
    remove_timestamps :abrt_reports
  end
end
