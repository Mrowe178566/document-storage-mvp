Rails.application.routes.draw do
  get "stored_files/new"
  get "stored_files/create"
  root "home#index"
  devise_for :users

  authenticate :user do
    resources :folders, only: [:index, :show, :new, :create]
  end

  authenticate :user do
    resources :stored_files, only: [:new, :create]
  end
end

# This is a blank app! Pick your first screen, build out the RCAV, and go from there. E.g.:
# get("/your_first_screen", { :controller => "pages", :action => "first" })
