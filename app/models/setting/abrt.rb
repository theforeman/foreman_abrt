class Setting::Abrt < ::Setting

  def self.load_defaults
    return unless super

    fqdn = Facter.value(:fqdn) || SETTINGS[:fqdn]
    lower_fqdn = fqdn.downcase

    ssl_cert     = "#{SETTINGS[:puppetvardir]}/ssl/certs/#{lower_fqdn}.pem"
    ssl_ca_file  = "#{SETTINGS[:puppetvardir]}/ssl/certs/ca.pem"
    ssl_priv_key = "#{SETTINGS[:puppetvardir]}/ssl/private_keys/#{lower_fqdn}.pem"
    #XXX initialize from ssl_{certificate,ca_file,priv_key}

    Setting.transaction do
      [
        self.set('abrt_server_url', N_('URL of the ABRT server to forward reports to'), 'https://localhost/faf'),
        self.set('abrt_server_verify_ssl', N_('Verify ABRT server certificate?'), true),
        self.set('abrt_server_ssl_certificate', N_('SSL certificate path that Foreman would use to communicate with ABRT server'), ssl_cert),
        self.set('abrt_server_ssl_priv_key', N_('SSL private key path that Foreman would use to communicate with ABRT server'), ssl_priv_key),
        self.set('abrt_server_ssl_ca_file', N_('SSL CA file that Foreman will use to communicate with ABRT server'), ssl_ca_file),
        self.set('abrt_automatically_forward', N_('Automatically forward every report to ABRT server?'), false),
      ].compact.each { |s| self.create s.update(:category => "Setting::Abrt") }
    end

    true

  end
end
