Rails.application.routes.draw do
  root "home#index"
  devise_for :users

  authenticate :user do
    resources :folders, only: [:index, :show, :new, :create]
  end
end

# This is a blank app! Pick your first screen, build out the RCAV, and go from there. E.g.:
# get("/your_first_screen", { :controller => "pages", :action => "first" })
