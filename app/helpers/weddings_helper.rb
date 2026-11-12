module WeddingsHelper
  def retained_photo_blob(photo)
    blob = photo.blob
    blob if blob&.persisted? && Wedding::PHOTO_TYPES.include?(blob.content_type) && blob.byte_size <= Wedding::MAX_PHOTO_SIZE
  end

  def public_wedding_url_for(wedding)
    port = Rails.configuration.x.app_port
    "#{Rails.configuration.x.app_protocol}://#{wedding.subdomain}.#{Rails.configuration.x.app_domain}#{port.present? ? ":#{port}" : ''}"
  end

  def wedding_date_label(wedding, format: :long)
    wedding.wedding_date ? l(wedding.wedding_date, format: format) : "Fecha por confirmar"
  end

  def event_time(event, wedding)
    l(event.starts_at.in_time_zone(wedding.timezone), format: :time_only)
  end

  def event_day(event, wedding)
    l(event.starts_at.in_time_zone(wedding.timezone).to_date, format: :short)
  end

  def days_until(wedding)
    (wedding.wedding_date - Date.current).to_i
  end

  def days_until_phrase(wedding)
    days = days_until(wedding)
    return "¡Hoy es el día!" if days.zero?
    return "Una fecha para recordar" if days.negative?

    "Faltan #{days} #{days == 1 ? "día" : "días"}"
  end

  def countdown_label(wedding)
    days = days_until(wedding)
    return "HOY ES NUESTRO DÍA" if days.zero?
    return "UN DÍA PARA RECORDAR SIEMPRE" if days.negative?

    "#{days} #{days == 1 ? "DÍA" : "DÍAS"} PARA SIEMPRE"
  end

  def wedding_status_label(wedding)
    wedding.published? ? "Publicada" : "Borrador"
  end

  def celebration_status(wedding)
    opens_at = l(wedding.celebration_begins_at.in_time_zone(wedding.timezone), format: :long)
    if wedding.landing_live?
      "Quienes entran ven ahora las fotos y los buenos deseos. Puedes volver a mostrar la invitación cuando quieras."
    elsif wedding.landing_invitation?
      "La página sigue mostrando la invitación. El cambio automático está en pausa."
    elsif wedding.celebration_open?
      "La celebración ya empezó. El enlace abre la página para subir fotos y dejar buenos deseos."
    else
      "El enlace sigue siendo la invitación hasta el #{opens_at}. Después abre las fotos y los buenos deseos."
    end
  end
end
