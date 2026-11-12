# Seeds are safe to rerun. Existing planner passwords and edited weddings are preserved.
planner_email = ENV.fetch("PLANNER_EMAIL", "planner@example.com").strip.downcase
User.find_or_create_by!(email: planner_email) do |planner|
  planner.password = ENV.fetch("PLANNER_PASSWORD", "wedding-planner-2026")
end

if Rails.env.development? && ENV.fetch("SEED_DEMO", "true") == "true" && !Wedding.exists?
  Wedding.transaction do
    sample = Wedding.create!(
      partner_one: "Eduardo", partner_two: "Raquel", subdomain: "eduardo-and-raquel",
      wedding_date: Date.current + 90.days, rsvp_deadline: Date.current + 70.days,
      theme: "sage", status: :published, timezone: "Mexico City",
      headline: "Juntos es un lugar hermoso.",
      invitation_text: "Con el corazón lleno y una sonrisa enorme, te invitamos a celebrar nuestra boda. Acompáñanos en un día de amor, risas y un poco de baile bajo las estrellas. Nuestro día favorito no estaría completo sin las personas que más queremos.",
      story: "Lo que empezó con un simple hola se volvió nuestra aventura favorita. Entre cafés, caminatas largas y todos los momentos pequeños, encontramos un hogar el uno en el otro.\n\nAhora estamos listos para el siguiente capítulo, y queremos empezarlo rodeados de las personas que amamos.",
      dress_code: "Formal de jardín · Un poco de color es bienvenido."
    )
    Time.use_zone(sample.timezone) do
      sample.events.create!(title: "La ceremonia", venue_name: "Jardín de los Olivos", starts_at: Time.zone.parse("#{sample.wedding_date} 16:00"), address: "San Miguel de Allende, Guanajuato, México", notes: "Llega 15 minutos antes para encontrar tu lugar.")
      sample.events.create!(title: "Cena y baile", venue_name: "Terraza de los Olivos", starts_at: Time.zone.parse("#{sample.wedding_date} 18:00"), address: "San Miguel de Allende, Guanajuato, México", notes: "Un brindis, una cena bonita y una pista de baile que te espera.")
    end
    Wedding.create!(partner_one: "Sofía", partner_two: "Daniel", subdomain: "sofia-and-daniel", wedding_date: Date.current + 145.days, theme: "rose", status: :draft, invitation_text: "Se acerca un día hermoso. Nos hace mucha ilusión celebrarlo contigo.", headline: "El comienzo de nuestro siempre.")
    Wedding.create!(partner_one: "Valentina", partner_two: "Andrés", subdomain: "valentina-and-andres", wedding_date: Date.current + 210.days, theme: "blue", status: :draft, invitation_text: "Acompáñanos en un día lleno de amor, risas y todas las personas que queremos.", headline: "Nuestra siguiente gran aventura.")
  end
end
