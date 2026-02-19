Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    resources :folders, only: [:index, :show, :new, :create]

    delete "stored_files/bulk_delete",
           to: "stored_files#bulk_delete",
           as: :bulk_delete_stored_files

    resources :stored_files, only: [:new, :create, :destroy]

    root "folders#index", as: :authenticated_root
  end

  unauthenticated do
    root "home#index"
  end
end
