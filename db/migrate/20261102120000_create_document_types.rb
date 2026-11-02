class CreateDocumentTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :document_types do |t|
      t.references :workspace, null: false, foreign_key: true
      t.string  :name, null: false
      t.boolean :expires, null: false, default: false
      t.integer :valid_for_months
      t.integer :remind_days_before
      t.boolean :requires_approval, null: false, default: false
      t.timestamps
    end

    # "Tax form" and "tax form" are the same type within one workspace.
    add_index :document_types, "workspace_id, lower(name)", unique: true,
              name: "index_document_types_on_workspace_and_lower_name"

    # Backs up the model validations: an expiring type always has a valid
    # period and a reminder, and a type that never expires has neither.
    # The IS NOT NULL checks matter: Postgres lets a row through when a
    # comparison like "NULL > 0" comes out unknown instead of false.
    add_check_constraint :document_types,
      "(expires AND valid_for_months IS NOT NULL AND remind_days_before IS NOT NULL " \
      "AND valid_for_months > 0 AND remind_days_before >= 0) OR " \
      "(NOT expires AND valid_for_months IS NULL AND remind_days_before IS NULL)",
      name: "document_types_expiry_settings"
  end
end
