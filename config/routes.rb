# frozen_string_literal: true

resources :workloads, only: %w[index]
resources :wl_user_datas, only: %w[edit update]

resources :wl_national_holiday
resources :wl_user_vacations

get  'wl_group_settings',              to: 'wl_group_settings#index',               as: :wl_group_settings
put  'wl_group_settings',              to: 'wl_group_settings#update'
post 'wl_group_settings/custom_field', to: 'wl_group_settings#create_custom_field', as: :wl_group_settings_custom_field
