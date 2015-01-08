class Setting::Abrt < ::Setting
  BLANK_ATTRS << "abrt_server_ssl_certificate"
  BLANK_ATTRS << "abrt_server_ssl_priv_key"
  BLANK_ATTRS << "abrt_server_ssl_ca_file"
  BLANK_ATTRS << "abrt_server_basic_auth_username"
  BLANK_ATTRS << "abrt_server_basic_auth_password"
  URI_ATTRS << "abrt_server_url"

  def self.load_defaults
    return unless super

    Setting.transaction do
      [
        self.set('abrt_server_url', N_('URL of the ABRT server to send reports to'), 'https://localhost/faf'),
        self.set('abrt_server_verify_ssl', N_('Verify ABRT server certificate?'), true),
        self.set('abrt_server_ssl_certificate', N_('SSL certificate path that Foreman would use to communicate with ABRT server'), ''),
        self.set('abrt_server_ssl_priv_key', N_('SSL private key path that Foreman would use to communicate with ABRT server'), ''),
        self.set('abrt_server_ssl_ca_file', N_('SSL CA file that Foreman will use to communicate with ABRT server'), ''),
        self.set('abrt_automatically_forward', N_('Automatically send every report to an ABRT server for analysis?'), false),
        self.set('abrt_server_basic_auth_required', N_('Does the server require authentication through username and password?'), false),
        self.set('abrt_server_basic_auth_username', N_('User name for server authentication'), ''),
        self.set('abrt_server_basic_auth_password', N_('Password for server authentication. WARNING: visible to anyone with access to settings'), ''),
      ].compact.each { |s| self.create s.update(:category => 'Setting::Abrt') }
    end

    true

  end
end
