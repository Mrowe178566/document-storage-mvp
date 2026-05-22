module Workspaces
  # Seeds a workspace with a manufacturing-oriented starter folder structure
  # so new workspaces don't land on an empty dashboard.
  #
  # Idempotent: re-running on the same workspace will only create folders that
  # don't already exist by name. This lets us re-run safely if a user clicks
  # the "Create Starter Structure" button on a partially-set-up workspace.
  #
  # Usage:
  #   result = Workspaces::Bootstrap.call(workspace: ws, user: current_user)
  #   if result.success?
  #     redirect_to folders_path, notice: "Added #{result.folders.size} folders."
  #   else
  #     redirect_to folders_path, alert: result.error
  #   end
  class Bootstrap
    # Curated for a manufacturing org — the kinds of buckets a quality manager,
    # production planner, or compliance lead would want on day one. Order
    # reflects priority of first thing they're likely to upload.
    MANUFACTURING_FOLDERS = [
      "Quality Control",
      "Production Plans",
      "Engineering Drawings",
      "Compliance & Certifications",
      "Supplier Documents",
      "Safety & Training"
    ].freeze

    Result = Struct.new(:success?, :folders, :error, keyword_init: true)

    def self.call(workspace:, user:, folder_names: MANUFACTURING_FOLDERS)
      new(workspace: workspace, user: user, folder_names: folder_names).call
    end

    def initialize(workspace:, user:, folder_names:)
      @workspace = workspace
      @user = user
      @folder_names = folder_names
    end

    def call
      created = []

      ActiveRecord::Base.transaction do
        @folder_names.each do |name|
          # Idempotent: skip if a folder with this name already exists.
          # We don't update existing folders — the user may have customized them.
          next if @workspace.folders.exists?(name: name)

          folder = @workspace.folders.create!(name: name, user: @user)
          created << folder
        end
      end

      Result.new(success?: true, folders: created, error: nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, folders: [], error: e.record.errors.full_messages.to_sentence)
    end
  end
end
