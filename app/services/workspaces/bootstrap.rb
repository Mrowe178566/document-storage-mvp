module Workspaces
  # Seeds a workspace with a manufacturing-oriented starter folder structure
  # and starter document types, so new workspaces don't land on an empty
  # dashboard.
  #
  # Idempotent: re-running on the same workspace will only create folders and
  # document types that don't already exist by name. This lets us re-run
  # safely if a user clicks the "Create Starter Structure" button on a
  # partially-set-up workspace.
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

    # A starting point only. Each workspace can rename, change, or remove
    # these, and add its own. Months and days are typical renewal cycles.
    MANUFACTURING_DOCUMENT_TYPES = [
      { name: "Quality certificate",        expires: true,  valid_for_months: 36, remind_days_before: 60, requires_approval: true },
      { name: "Insurance certificate",      expires: true,  valid_for_months: 12, remind_days_before: 30, requires_approval: true },
      { name: "Material test report",       expires: true,  valid_for_months: 12, remind_days_before: 30, requires_approval: false },
      { name: "Compliance declaration",     expires: true,  valid_for_months: 12, remind_days_before: 30, requires_approval: true },
      { name: "Supplier quality agreement", expires: true,  valid_for_months: 36, remind_days_before: 90, requires_approval: true },
      { name: "Procedure or drawing",       expires: false, requires_approval: true },
      { name: "Training record",            expires: true,  valid_for_months: 12, remind_days_before: 30, requires_approval: false },
      { name: "Tax form",                   expires: false, requires_approval: false }
    ].freeze

    Result = Struct.new(:success?, :folders, :document_types, :error, keyword_init: true)

    def self.call(workspace:, user:, folder_names: MANUFACTURING_FOLDERS,
                  document_types: MANUFACTURING_DOCUMENT_TYPES)
      new(workspace: workspace, user: user, folder_names: folder_names, document_types: document_types).call
    end

    def initialize(workspace:, user:, folder_names:, document_types:)
      @workspace = workspace
      @user = user
      @folder_names = folder_names
      @document_types = document_types
    end

    def call
      created = []
      created_types = []

      ActiveRecord::Base.transaction do
        @folder_names.each do |name|
          # Idempotent: skip if a folder with this name already exists.
          # We don't update existing folders — the user may have customized them.
          next if @workspace.folders.exists?(name: name)

          folder = @workspace.folders.create!(name: name, user: @user)
          created << folder
        end

        @document_types.each do |attrs|
          # Names match ignoring case, the same rule the unique index uses.
          # Existing types keep their settings; the workspace may have tuned them.
          next if @workspace.document_types.exists?([ "lower(name) = ?", attrs[:name].downcase ])

          created_types << @workspace.document_types.create!(attrs)
        end
      end

      Result.new(success?: true, folders: created, document_types: created_types, error: nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, folders: [], document_types: [], error: e.record.errors.full_messages.to_sentence)
    end
  end
end
