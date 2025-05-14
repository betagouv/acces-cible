# Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  resources :sites do
    collection do
      post :upload
      get :upload, to: redirect("/sites/new")
    end
    resources :audits, only: [:create, :show]
  end

  # Static pages
  scope controller: :pages do
    root action: :accueil
    get "accessibilite", as: :accessibilite
    get "plan", as: :plan
    get "contact", as: :contact
    get "mentions-legales", as: :mentions_legales
    get "cookies", as: :cookies
    get "donnees-personnelles", as: :donnees_personnelles
  end

  # Error pages
  scope controller: :errors, via: :all do
    match "/404", action: :not_found
    match "/500", action: :internal_server_error
  end

  direct :commit do |hash|
    "https://github.com/betagouv/acces-cible/commits/#{hash}"
  end

  # Operational URLs
  mount MissionControl::Jobs::Engine, at: "/jobs"
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
