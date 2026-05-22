module Workspaces
  # Creates a Workspace and makes the given user its Owner, atomically.
  #
  # Used by:
  #   * Users::RegistrationsController#create  (signup)
  #   * WorkspacesController#create            (logged-in user adds a workspace)
  #
  # Keeps the multi-tenant creation logic in one place so controllers stay slim
  # and the "new workspace + owner membership" pair can never drift apart.
  #
  # Usage:
  #   result = Workspaces::Create.call(user: current_user, name: "Acme Inc.")
  #   if result.success?
  #     redirect_to workspace_path(result.workspace)
  #   else
  #     flash.now[:alert] = result.error
  #     render :new
  #   end
  class Create
    Result = Struct.new(:success?, :workspace, :error, keyword_init: true)

    def self.call(user:, name:)
      new(user: user, name: name).call
    end

    def initialize(user:, name:)
      @user = user
      @name = name.to_s.strip
    end

    def call
      return failure("Workspace name can't be blank") if @name.blank?

      workspace = nil
      ActiveRecord::Base.transaction do
        workspace = Workspace.create!(name: @name)
        Membership.create!(user: @user, workspace: workspace, role: "owner")
      end

      Result.new(success?: true, workspace: workspace, error: nil)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages.to_sentence)
    end

    private

    def failure(message)
      Result.new(success?: false, workspace: nil, error: message)
    end
  end
end
