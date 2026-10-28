Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  domain = Rails.configuration.x.app_domain
  planner_hosts = [domain, "app.#{domain}"]
  planner_hosts << "127.0.0.1" if Rails.env.development? || Rails.env.test?

  constraints ->(request) { planner_hosts.include?(request.host) } do
    root "weddings#index"
    resource :session, only: %i[new create destroy]
    resources :weddings do
      member do
        get :preview
        patch :publish
        patch :unpublish
      end
      resources :rsvps, only: :index, defaults: { format: :csv }
    end
  end

  constraints ->(request) { request.host.match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\.#{Regexp.escape(domain)}\z/) && !planner_hosts.include?(request.host) } do
    get "/", to: "public_weddings#show", as: :guest_root
    get "/fiesta", to: "public_weddings#live", as: :guest_live
    post "/rsvp", to: "public_weddings#respond", as: :guest_rsvp
  end
end
