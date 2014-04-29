Rails.application.routes.draw do

  resources :abrt_reports do
    member do
      get 'json'
    end
  end
  get 'hosts/:host_id/abrt_reports', :to => 'abrt_reports#index', :constraints => {:host_id => /[^\/]+/}, :as => "host_abrt_reports"

end
