module ApplicationHelper
  def display_name(user)
    user.email.split("@").first.capitalize
  end
end
