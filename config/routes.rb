resources :settings_templates
get 'settings_templates/:copy_from/copy', to: 'settings_templates#new', as: 'copy_settings_template'

scope :intouch do
  put 'save_settings' => 'intouch#save_settings'
end

resources :telegram_groups, only: [:index, :show, :destroy]

resources :intouch_cron_jobs do
  collection do
    get :init
  end
end
