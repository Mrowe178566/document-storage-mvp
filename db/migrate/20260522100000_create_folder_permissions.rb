class CreateFolderPermissions < ActiveRecord::Migration[8.0]
  def change
    create_table :folder_permissions do |t|
      t.references :folder, null: false, foreign_key: true
      t.references :user,   null: false, foreign_key: true
      t.timestamps
    end

    # A user can only have one permission row per folder.
    add_index :folder_permissions, [ :folder_id, :user_id ], unique: true,
              name: "index_folder_permissions_on_folder_and_user"
  end
end
