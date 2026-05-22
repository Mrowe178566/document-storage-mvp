Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

  authenticated :user do
    resources :folders do
      resource :permissions, only: [ :edit, :update ], controller: "folder_permissions"
    end

    delete "stored_files/bulk_delete",
           to: "stored_files#bulk_delete",
           as: :bulk_delete_stored_files

    resources :stored_files, only: [ :create, :destroy ]

    resource :workspace, only: [ :show, :update ] do
      post :bootstrap
      resources :invitations, only: [ :new, :create ]
      resources :memberships, only: [ :update, :destroy ], module: :workspaces
    end

    resources :workspaces, only: [ :new, :create ] do
      post :switch, on: :member, to: "workspaces/switches#create"
    end

    get "recent",  to: "recent_activities#index", as: :recent_activities
    get "team",    to: "team#index",              as: :team
    get "pinned",  to: "pins#index",              as: :pins

    root "folders#index", as: :authenticated_root
  end

  # Public invitation acceptance — no authentication required
  get  "invitations/:token", to: "invitation_acceptances#show", as: :invitation_acceptance
  patch "invitations/:token", to: "invitation_acceptances#update"

  unauthenticated do
    root "home#index"
  end
end
