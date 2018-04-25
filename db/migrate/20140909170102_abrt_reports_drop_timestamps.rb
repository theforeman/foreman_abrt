class AbrtReportsDropTimestamps < ActiveRecord::Migration[4.2]
  def change
    remove_timestamps :abrt_reports
  end
end
