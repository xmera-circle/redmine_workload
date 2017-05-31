# -*- encoding : utf-8 -*-
if Rails::VERSION::MAJOR < 3
  ActionController::Routing::Routes.draw do |map|
    map.connect 'work_load/:action/:id', :controller => :work_load
  end
else
  match 'work_load/(:action(/:id))',via: [:get], :controller => 'work_load'
  match 'wl_user_data/(:action(/:id))',via: [:get, :post], :controller => 'wl_user_datas'  
  resources :wl_national_holiday
  resources :wl_user_vacations
end
