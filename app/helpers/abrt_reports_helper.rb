module AbrtReportsHelper
  def simple_format_if_multiline str
    if str.include? "\n"
      simple_format str
    else
      str
    end
  end

  def count_abrt_reports abrt_reports
    data = []
    interval = 1.hours
    start = Time.now.utc - 24.hours
    (0..23).each do |i|
      t = start + (interval * i)
      data << [24-i, abrt_reports.where(:created_at => t..(t+interval)).count]
    end
    data
  end

  def render_abrt_graph abrt_reports, options = {}
    data = count_abrt_reports abrt_reports
    flot_bar_chart 'abrt_graph', _('Hours Ago'), _('Number of crashes'), data, options
  end
end
