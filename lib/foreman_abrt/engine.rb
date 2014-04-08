require 'deface'

module ForemanAbrt
  class Engine < ::Rails::Engine

    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/helpers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/overrides"]

    # Add any db migrations
    initializer "foreman_abrt.load_app_instance_data" do |app|
      app.config.paths['db/migrate'] += ForemanAbrt::Engine.paths['db/migrate'].existent
    end

    initializer 'foreman_abrt.register_plugin', :after=> :finisher_hook do |app|
      Foreman::Plugin.register :foreman_abrt do
        requires_foreman '>= 1.4'

        # Add permissions
        security_block :foreman_abrt do
          permission :view_foreman_abrt, {:'foreman_abrt/hosts' => [:new_action] }
        end

        # Add a new role called 'Discovery' if it doesn't exist
        role "ForemanAbrt", [:view_foreman_abrt]

        #add menu entry
        menu :top_menu, :template,
             :url_hash => {:controller => :'foreman_abrt/hosts', :action => :new_action },
             :caption  => 'ForemanAbrt',
             :parent   => :hosts_menu,
             :after    => :hosts
      end
    end

    #Include concerns in this config.to_prepare block
    config.to_prepare do
      begin
        Host::Managed.send(:include, ForemanAbrt::HostExtensions)
        HostsHelper.send(:include, ForemanAbrt::HostsHelperExtensions)
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
