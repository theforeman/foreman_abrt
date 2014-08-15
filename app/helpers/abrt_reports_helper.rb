module AbrtReportsHelper
  def simple_format_if_multiline str
    if str.include? "\n"
      simple_format str
    else
      str
    end
  end
end
