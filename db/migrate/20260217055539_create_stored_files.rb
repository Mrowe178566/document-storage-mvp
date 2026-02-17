class CreateStoredFiles < ActiveRecord::Migration[8.0]
  def change
    create_table :stored_files do |t|
      t.string :file_name
      t.references :user, foreign_key: true
      t.references :folder, foreign_key: true

      t.timestamps
    end
  end
end
