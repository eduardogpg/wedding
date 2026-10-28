module WeddingsHelper
  def public_wedding_url_for(wedding)
    port = Rails.configuration.x.app_port
    "#{Rails.configuration.x.app_protocol}://#{wedding.subdomain}.#{Rails.configuration.x.app_domain}#{port.present? ? ":#{port}" : ''}"
  end

  def wedding_date_label(wedding, format: "%B %-d, %Y")
    wedding.wedding_date&.strftime(format) || "Date to be decided"
  end

  def event_time(event, wedding)
    event.starts_at.in_time_zone(wedding.timezone).strftime("%-I:%M %p")
  end

  def days_until(wedding)
    (wedding.wedding_date - Date.current).to_i
  end
end
