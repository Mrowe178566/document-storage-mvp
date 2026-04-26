desc "Fill the database tables with some sample data"
task({ sample_data: :environment }) do
  puts "Clearing existing data..."
  StoredFile.destroy_all
  Folder.destroy_all
  User.destroy_all

  puts "Creating sample user..."
  user = User.create!(
    email: "demo@example.com",
    password: "password123"
  )

  puts "Creating sample folders..."
  [ "Client Projects", "Invoices", "Creative Assets" ].each do |folder_name|
    folder = user.folders.create!(name: folder_name)
    puts "  Created folder: #{folder.name}"

    puts "  Creating sample files in #{folder.name}..."
    3.times do |i|
      folder.stored_files.create!(
        file_name: "sample_file_#{i + 1}.pdf",
        user: user
      )
      puts "    Created file: sample_file_#{i + 1}.pdf"
    end
  end

  puts "Done! Log in with demo@example.com / password123"
end
