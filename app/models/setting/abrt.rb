class Setting::Abrt < ::Setting

  def self.load_defaults
    return unless super

    Setting.transaction do
      [
        self.set('abrt_server_url', N_('URL of the ABRT server to forward reports to'), ''),
        self.set('abrt_server_verify_ssl', N_('Verify ABRT server certificate?'), true),
        #self.set('abrt_server_ssl_certificate', N_('SSL certificate path that Foreman would use to communicate with ABRT server'), '/tmp/a.txt'),
        #self.set('abrt_server_ssl_priv_key', N_('SSL private key path that Foreman would use to communicate with ABRT server'), '/tmp/b.txt'),
        self.set('abrt_automatically_forward', N_('Automatically forward every report to ABRT server?'), false),
      ].compact.each { |s| self.create s.update(:category => "Setting::Abrt") }
    end

    true

  end
end
