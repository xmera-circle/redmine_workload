# frozen_string_literal: true

match 'work_load/(:action(/:id))', via: [:get], controller: 'work_load'
match 'wl_user_data/(:action(/:id))', via: %i[get post], controller: 'wl_user_datas'
resources :wl_national_holiday
resources :wl_user_vacations
