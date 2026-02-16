Rails.application.routes.draw do
 root "home#index" 
 get "home/index" 
 devise_for :users
end


# This is a blank app! Pick your first screen, build out the RCAV, and go from there. E.g.:
  # get("/your_first_screen", { :controller => "pages", :action => "first" })
