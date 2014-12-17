module AbrtReportsHelper
  def simple_format_if_multiline(str)
    if str and str.include? "\n"
      simple_format str
    else
      str
    end
  end

  def count_abrt_reports(abrt_reports)
    range_days = 14
    data       = []
    now        = Time.now.utc
    start      = now - range_days.days
    by_day     = abrt_reports.where(:reported_at => start..now).
      group('DATE(reported_at)').
      sum(:count)

    range_days.downto(1) do |days_back|
      date    = (now - (days_back-1).days).strftime('%Y-%m-%d')
      crashes = (by_day[date] || 0)
      data << [days_back, crashes]
    end
    data
  end

  def render_abrt_graph(abrt_reports, options = {})
    data = count_abrt_reports abrt_reports
    flot_bar_chart 'abrt_graph', _('Days Ago'), _('Number of crashes'), data, options
  end

  class StringIOWithPath < StringIO
    def initialize(string, path, content_type)
      super(string)
      @path         = path
      @content_type = content_type
    end

    attr_reader :path, :content_type
  end

  def send_to_abrt_server(abrt_report)
    request_params = {
      :timeout      => 60,
      :open_timeout => 10,
      :verify_ssl   => Setting[:abrt_server_verify_ssl] ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
    }

    if Setting[:abrt_server_ssl_ca_file] && !Setting[:abrt_server_ssl_ca_file].empty?
      request_params[:ssl_ca_file] = Setting[:abrt_server_ssl_ca_file]
    end

    if Setting[:abrt_server_ssl_certificate] && !Setting[:abrt_server_ssl_certificate].empty? \
       && Setting[:abrt_server_ssl_priv_key] && !Setting[:abrt_server_ssl_priv_key].empty?
      request_params[:ssl_client_cert] = OpenSSL::X509::Certificate.new(File.read(Setting[:abrt_server_ssl_certificate]))
      request_params[:ssl_client_key]  = OpenSSL::PKey::RSA.new(File.read(Setting[:abrt_server_ssl_priv_key]))
    end

    resource    = RestClient::Resource.new(Setting[:abrt_server_url], request_params)
    report_file = StringIOWithPath.new(abrt_report.json, '*buffer*', 'application/json')
    response    = resource['reports/new/'].post({ :file => report_file, :multipart => true }, :content_type => :json, :accept => :json)

    if response.code != 202
      logger.error "Failed to send the report for analysis: #{response.code}: #{response.to_str}"
      raise ::Foreman::Exception.new(N_('Failed to forward problem report: %s: %s', response.code, response.to_str))
    end

    JSON.parse(response.body)
  end

  def format_reason(reason)
    if reason.nil? or reason.empty?
      _('Unknown')
    else
      reason
    end
  end
end
