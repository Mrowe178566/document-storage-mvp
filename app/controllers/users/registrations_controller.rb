class Users::RegistrationsController < Devise::RegistrationsController
  def create
    build_resource(sign_up_params)
    resource.workspace_name = workspace_name_param

    if resource.workspace_name.blank?
      resource.errors.add(:workspace_name, "can't be blank")
      clean_up_passwords resource
      set_minimum_password_length
      render :new, status: :unprocessable_entity
      return
    end

    saved_user_and_workspace = User.transaction do
      if resource.save
        result = Workspaces::Create.call(user: resource, name: resource.workspace_name)
        if result.success?
          session[:current_workspace_id] = result.workspace.id
          true
        else
          resource.errors.add(:workspace_name, result.error)
          raise ActiveRecord::Rollback
        end
      else
        false
      end
    end

    if saved_user_and_workspace
      sign_up(resource_name, resource)
      redirect_to after_sign_up_path_for(resource),
                  notice: "Welcome to File Vault! Your workspace #{resource.workspace_name} is ready."
    else
      clean_up_passwords resource
      set_minimum_password_length
      render :new, status: :unprocessable_entity
    end
  end

  private

  def workspace_name_param
    params.dig(:user, :workspace_name).to_s.strip
  end
end
