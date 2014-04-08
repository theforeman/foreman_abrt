Rails.application.routes.draw do

  match 'new_action', :to => 'foreman_abrt/hosts#new_action'

end
