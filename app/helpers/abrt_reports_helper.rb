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
      data << [24-i, abrt_reports.where(:reported_at => t..(t+interval)).count]
    end
    data
  end

  def render_abrt_graph abrt_reports, options = {}
    data = count_abrt_reports abrt_reports
    flot_bar_chart 'abrt_graph', _('Hours Ago'), _('Number of crashes'), data, options
  end

  def send_to_abrt_server abrt_report
    request_params = {
      :timeout => 60,
      :open_timeout => 10,
      :verify_ssl => Setting[:abrt_server_verify_ssl] ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
    }

    if Setting[:abrt_server_ssl_ca_file] && !Setting[:abrt_server_ssl_ca_file].empty?
      request_params[:ssl_ca_file] = Setting[:abrt_server_ssl_ca_file]
    end

    if Setting[:abrt_server_ssl_certificate] && !Setting[:abrt_server_ssl_certificate].empty? \
       && Setting[:abrt_server_ssl_priv_key] && !Setting[:abrt_server_ssl_priv_key].empty?
      request_params[:ssl_client_cert] = OpenSSL::X509::Certificate.new(File.read(Setting[:abrt_server_ssl_certificate]))
      request_params[:ssl_client_key]  = OpenSSL::PKey::RSA.new(File.read(Setting[:abrt_server_ssl_priv_key]))
    end

    resource = RestClient::Resource.new(Setting[:abrt_server_url], request_params)
    response = resource['reports/new/'].post({:file => abrt_report.json, :multipart => true}, :content_type => :json, :accept => :json)

    if response.code != 202
      logger.error "Failed to forward bug report: #{response.code}: #{response.to_str}"
      raise ::Foreman::Exception.new(N_("Failed to forward bug report: %s: %s", response.code, response.to_str))
    end

    JSON.parse(response.body)
  end
end
