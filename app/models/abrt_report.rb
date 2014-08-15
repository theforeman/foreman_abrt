class AbrtReport < ActiveRecord::Base
  include Authorizable

  audited :associated_with => :host, :allow_mass_assignment => true

  belongs_to_host
  has_one :environment, :through => :host
  has_one :hostgroup, :through => :host

  has_many :abrt_report_response_destinations, :dependent => :destroy
  has_many :abrt_report_response_solutions, :dependent => :destroy

  validates :json, :presence => true
  validates :count, :numericality => { :only_integer => true, :greater_than => 0 }
  validates :duphash, :format => { :with => /\A[0-9a-fA-F]+\z/ }, :allow_blank => true

  scoped_search :in => :host,        :on => :name,  :complete_value => true, :rename => :host
  scoped_search :in => :environment, :on => :name,  :complete_value => true, :rename => :environment
  scoped_search :in => :hostgroup,   :on => :name,  :complete_value => true, :rename => :hostgroup
  scoped_search :in => :hostgroup,   :on => :title, :complete_value => true, :rename => :hostgroup_fullname
  scoped_search :in => :hostgroup,   :on => :title, :complete_value => true, :rename => :hostgroup_title

  scoped_search :on => :reason,       :complete_value => true
  scoped_search :on => :duphash,      :complete_value => true
  scoped_search :on => :count,        :complete_value => true, :only_explicit => true
  scoped_search :on => :reported_at,  :complete_value => true, :default_order => :desc, :rename => :reported, :only_explicit => true

  scoped_search :on => :forwarded_at,     :complete_value => true, :rename => :forwarded, :only_explicit => true
  scoped_search :on => :response_known,   :complete_value => true, :rename => :known,     :only_explicit => true
  scoped_search :on => :response_message, :complete_value => true, :rename => :response
  scoped_search :on => :response_bthash,  :complete_value => true, :rename => :bthash

  scoped_search :in => :abrt_report_response_destination, :on => :reporter, :complete_value => true, :rename => :destination_reporter
  scoped_search :in => :abrt_report_response_destination, :on => :desttype, :complete_value => true, :rename => :destination_type
  scoped_search :in => :abrt_report_response_destination, :on => :value   , :complete_value => true, :rename => :destination_value

  scoped_search :in => :abrt_report_response_solution, :on => :cause, :complete_value => true, :rename => :solution_cause
  scoped_search :in => :abrt_report_response_solution, :on => :note,  :complete_value => true, :rename => :solution_note
  scoped_search :in => :abrt_report_response_solution, :on => :url,   :complete_value => true, :rename => :solution_url

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
    request_params = {
      :timeout => 60,
      :open_timeout => 10,
      :verify_ssl => Setting[:abrt_server_verify_ssl] ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
    }

    if Setting[:abrt_server_ssl_ca_file] && !Setting[:abrt_server_ssl_ca_file].empty?
      request_params[:ssl_ca_file] = Setting[:abrt_server_ssl_ca_file]
    end

    # XXX what certificates will be used if communicating with e.g. customer portal?
    if Setting[:abrt_server_ssl_certificate] && !Setting[:abrt_server_ssl_certificate].empty? \
       && Setting[:abrt_server_ssl_priv_key] && !Setting[:abrt_server_ssl_priv_key].empty?
      request_params[:ssl_client_cert] = OpenSSL::X509::Certificate.new(File.read(Setting[:abrt_server_ssl_certificate]))
      request_params[:ssl_client_key]  = OpenSSL::PKey::RSA.new(File.read(Setting[:abrt_server_ssl_priv_key]))
    end

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
