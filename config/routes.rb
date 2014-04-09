Rails.application.routes.draw do

  resources :abrt_reports

  match 'new_action', :to => 'foreman_abrt/hosts#new_action'

end
