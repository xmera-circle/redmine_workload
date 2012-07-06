Rails.application.routes.draw do
  match 'work_load/show', :to => "work_load#show"
end
