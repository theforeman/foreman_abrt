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

  def send_to_abrt_server(abrt_report, username = nil, password = nil)
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

    # basic auth
    if !Setting[:abrt_server_basic_auth_username].empty? && !Setting[:abrt_server_basic_auth_password].empty?
      request_params[:user] = Setting[:abrt_server_basic_auth_username]
      request_params[:password] = Setting[:abrt_server_basic_auth_password]
    elsif username && password
      request_params[:user] = username
      request_params[:password] = password
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

  def using_redhat_server?
    match = %r{^https://[^/]*access\.redhat\.com/}.match(Setting[:abrt_server_url])
    !!match
  end

  def ask_for_auth?
    if !Setting[:abrt_server_basic_auth_username].empty? && !Setting[:abrt_server_basic_auth_password].empty?
      false
    elsif Setting[:abrt_server_basic_auth_required] || using_redhat_server?
      true
    else
      false
    end
  end

  def display_forward_button(abrt_report)
    if ask_for_auth?
      button_tag _('Send for analysis'), :id => 'forward_auth_button', :class => 'btn btn-success'
    else
      options = { :class => 'btn btn-success', :method => :post }
      if abrt_report.forwarded_at
        options[:confirm] = _('The report has already been sent. Sending it again will overwrite the previous response.')
      end
      link_to _('Send for analysis'), forward_abrt_report_path(abrt_report), options
    end
  end

  def forward_auth_title
    if using_redhat_server?
      _('Please provide Red Hat Customer Portal credentials')
    else
      _('Please provide ABRT server credentials')
    end
  end

  def forward_auth_login
    if using_redhat_server?
      _('Red Hat Login')
    else
      _('Login')
    end
  end

  def forward_auth_text
    if using_redhat_server?
      _('The problem report will be sent to Red Hat in order to determine if a solution exists. '\
        'You need to provide your Red Hat Customer Portal login and password in order to proceed.')
    else
      _('Your ABRT server is configured to require login and password.')
    end
  end
end
