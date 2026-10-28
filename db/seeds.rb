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
      headline: "Together is a beautiful place to be.",
      invitation_text: "With full hearts and the biggest smiles, we invite you to celebrate our wedding. Join us for a day of love, laughter, and a little dancing under the stars. Our favorite day wouldn’t be complete without our favorite people.",
      story: "What started with a simple hello became our favorite adventure. Through coffee dates, long walks, and all the little moments in between, we found a home in each other.\n\nNow we’re ready for our next chapter, and we can’t wait to begin it surrounded by the people we love.",
      dress_code: "Garden formal · A little color encouraged."
    )
    Time.use_zone(sample.timezone) do
      sample.events.create!(title: "The ceremony", venue_name: "Jardín de los Olivos", starts_at: Time.zone.parse("#{sample.wedding_date} 16:00"), address: "San Miguel de Allende, Guanajuato, Mexico", notes: "Please arrive 15 minutes early to find your seat.")
      sample.events.create!(title: "Dinner & dancing", venue_name: "Terraza de los Olivos", starts_at: Time.zone.parse("#{sample.wedding_date} 18:00"), address: "San Miguel de Allende, Guanajuato, Mexico", notes: "A toast to love, a beautiful dinner, and a dance floor waiting for you.")
    end
    Wedding.create!(partner_one: "Sofía", partner_two: "Daniel", subdomain: "sofia-and-daniel", wedding_date: Date.current + 145.days, theme: "rose", status: :draft, invitation_text: "A beautiful day is on its way. We can’t wait to celebrate with you.", headline: "The beginning of our forever.")
    Wedding.create!(partner_one: "Valentina", partner_two: "Andrés", subdomain: "valentina-and-andres", wedding_date: Date.current + 210.days, theme: "blue", status: :draft, invitation_text: "Join us for a day filled with love, laughter, and all our favorite people.", headline: "Our next great adventure.")
  end
end
