class AbrtReport < ActiveRecord::Base
  include Authorizable

  belongs_to_host

  has_many :abrt_report_response_destinations, :dependent => :destroy
  has_many :abrt_report_response_solutions, :dependent => :destroy

  validates :json, :presence => true
  #validates :reason, :presence => true
  validates :count, :numericality => { :only_integer => true, :greater_than => 0 }
  validates :duphash, :format => { :with => /\A[0-9a-fA-F]+\z/ }, :allow_blank => true

  #TODO
  scoped_search :on => [:reason, :duphash]

  def self.import(json)
    host = Host.find_by_name(json[:host])
    reports = []
    AbrtReport.transaction do
      json[:reports].each do |report|
        # import one report
        reason = nil # try extracting reason from the report
        reason ||= report[:full][:reason] if report[:full].has_key? :reason
        reports << AbrtReport.create!(:host => host, :count => report[:count], :json => report[:full].to_json,
                                      :duphash => report[:duphash], :reason => reason,
                                      :reported_at => report[:reported_at])
      end
    end
    reports
  end

  # XXX is the network communication acceptable in a model?
  def forward
    # XXX what certificates will be used if communicating with e.g. customer portal?
    # TODO only if https
    request_params = {
      :timeout => 60,
      :open_timeout => 10,
      :ssl_client_cert  =>  OpenSSL::X509::Certificate.new(File.read(Setting[:abrt_server_ssl_certificate])),
      :ssl_client_key   =>  OpenSSL::PKey::RSA.new(File.read(Setting[:abrt_server_ssl_priv_key])),
      :ssl_ca_file      =>  Setting[:abrt_server_ssl_ca_file],
      :verify_ssl => Setting[:abrt_server_verify_ssl] ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
    }

    resource = RestClient::Resource.new(Setting[:abrt_server_url], request_params)
    response = resource['reports/new/'].post({:file => json, :multipart => true}, :content_type => :json, :accept => :json)

    if response.code != 202
      logger.error "Failed to forward bug report: #{response.code}: #{response.to_str}"
      raise ::Foreman::Exception.new(N_("Failed to forward bug report: %s: %s", response.code, response.to_str))
    end

    JSON.parse(response.body)
  end

  def add_response(response)
    self.transaction do
      abrt_report_response_solutions.clear
      abrt_report_response_destinations.clear

      self.forwarded_at = Time.now
      self.response_known = response['result']
      self.response_message = response['message']
      self.response_bthash = response['bthash']

      if response['solutions']
        response['solutions'].each do |solution|
          abrt_report_response_solutions.create!(
            :cause => solution['cause'],
            :note => solution['note'],
            :url => solution['url']
          )
        end
      end

      if response['reported_to']
        response['reported_to'].each do |destination|
          abrt_report_response_destinations.create!(
            :desttype => destination['type'],
            :value => destination['value'],
            :reporter => destination['reporter']
          )
        end
      end

      save!
    end
  end
end
