class AddDocumentTypeAndExpiresOnToStoredFiles < ActiveRecord::Migration[8.1]
  def change
    # Optional, so every file uploaded before document types existed stays valid.
    # Removing a type clears it from its files instead of deleting them.
    add_reference :stored_files, :document_type, null: true,
                  foreign_key: { on_delete: :nullify }

    # Stored on the file, not worked out from the type each time, so changing
    # a type's valid period later never moves dates on documents already filed.
    add_column :stored_files, :expires_on, :date

    # For the upcoming "what expires in the next 30 days" views.
    add_index :stored_files, [ :workspace_id, :expires_on ]
  end
end
