if Rails::VERSION::MAJOR < 3
  ActionController::Routing::Routes.draw do |map|
    map.connect 'work_load/:action/:id', :controller => :work_load
  end
else
  match 'work_load/(:action(/:id))', :controller => 'work_load'
end

