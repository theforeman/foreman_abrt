require 'deface'

module ForemanAbrt
  class Engine < ::Rails::Engine

    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/helpers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/overrides"]

    # Initialize settings
    initializer 'foreman_abrt.load_default_settings', :before => :load_config_initializers do |app|
      require_dependency File.expand_path('../../../app/models/setting/abrt.rb', __FILE__) if (Setting.table_exists? rescue(false))
    end

    # Add any db migrations
    initializer "foreman_abrt.load_app_instance_data" do |app|
      app.config.paths['db/migrate'] += ForemanAbrt::Engine.paths['db/migrate'].existent
    end

    initializer 'foreman_abrt.register_plugin', :after=> :finisher_hook do |app|
      Foreman::Plugin.register :foreman_abrt do
        requires_foreman '>= 1.5'

        # Add permissions
        security_block :foreman_abrt do
          permission :view_abrt_reports,    {:abrt_reports => [:index, :show, :auto_complete_search] }
          permission :destroy_abrt_reports, {:abrt_reports => [:destroy] }
          permission :upload_abrt_reports,  {:abrt_reports => [:create] }
          permission :forward_abrt_reports, {:abrt_reports => [:forward] }
        end

        # Add a new role called 'ForemanAbrt' if it doesn't exist
        # XXX
        role "ForemanAbrt", [:view_abrt_reports, :destroy_abrt_reports, :upload_abrt_reports, :forward_abrt_reports]

        #add menu entry
        menu :top_menu, :template,
             :url_hash => {:controller => :'abrt_reports', :action => :index},
             :caption  => _('Bug reports'),
             :parent   => :monitor_menu,
             :after    => :reports
      end
    end

    #Include concerns in this config.to_prepare block
    config.to_prepare do
      begin
        Host::Managed.send(:include, ForemanAbrt::HostExtensions)
      rescue => e
        puts "ForemanAbrt: skipping engine hook (#{e.to_s})"
      end
    end

    rake_tasks do
      Rake::Task['db:seed'].enhance do
        ForemanAbrt::Engine.load_seed
      end
    end

  end
end
