# Run inside the web container with bin/rails runner script/local_urls.rb.
settings = Rails.configuration.x
port = settings.app_port.present? ? ":#{settings.app_port}" : ""
base = "#{settings.app_protocol}://"

puts "\nBoda is running in the background. Open one of these URLs in your browser:"
puts "  Planner:      #{base}app.#{settings.app_domain}#{port}"
puts "  Root address: #{base}#{settings.app_domain}#{port}"

if (wedding = Wedding.published.chronological.first)
  wedding_url = "#{base}#{wedding.subdomain}.#{settings.app_domain}#{port}"
  puts "  Wedding page: #{wedding_url}"
end

puts "\nSign in with your planner account (local defaults are in README.md)."
puts "Follow server output with: make logs\n\n"
