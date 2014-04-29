Rails.application.routes.draw do

  resources :abrt_reports, :only => [:index, :show, :destroy] do
    member do
      get 'json'
    end
  end
  get 'hosts/:host_id/abrt_reports', :to => 'abrt_reports#index',
                                     :constraints => {:host_id => /[^\/]+/},
                                     :as => "host_abrt_reports"

  namespace :api, :defaults => {:format => 'json'} do
    scope "(:apiv)", :module => :v2,
                     :defaults => {:apiv => 'v2'},
                     :apiv => /v1|v2/,
                     :constraints => ApiConstraints.new(:version => 2) do
      resources :abrt_reports, :only => [:create]
    end
  end

end
