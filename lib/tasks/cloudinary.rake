namespace :cloudinary do
  desc "Switch existing Cloudinary files from public to authenticated delivery. " \
       "Dry run unless CONFIRM=1. LIMIT=n tries only the first n files."
  task make_private: :environment do
    result = Storage::MakeCloudinaryFilesPrivate.call(
      apply: ENV["CONFIRM"] == "1",
      limit: ENV["LIMIT"]&.to_i
    )
    exit 1 if result.failed.any?
  end
end
