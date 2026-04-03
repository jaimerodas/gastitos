Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "transactions#index"

  scope path_names: { new: "crear", edit: "editar" } do
    resource :session, only: [ :new, :create, :destroy ], path: "sesion"
    resources :password_resets, only: [ :new, :create, :edit, :update ], param: :token, path: "restablecer"
    resources :users, only: [ :new, :create, :index, :show, :destroy ], path: "usuarios" do
      resource :approval, only: [ :create, :destroy ], path: "aprobacion"
      resource :role, only: [ :update ], path: "rol"
      get :activity_log, on: :member, path: "actividad"
    end
    resources :transactions, only: [ :create, :edit, :update, :destroy ], path: "transacciones"
    resources :categories, only: [ :create ], path: "categorias"
    resources :monthly_periods, only: [ :index, :show, :edit, :update ], path: "meses"
  end
end
