# Keep Supabase free tier from pausing due to inactivity
if Rails.env.production?
  Thread.new do
    loop do
      sleep 5.days
      ActiveRecord::Base.connection.execute("SELECT 1")
      Rails.logger.info "Supabase keep-alive ping sent"
    rescue => e
      Rails.logger.error "Keep-alive ping failed: #{e.message}"
    end
  end
end
