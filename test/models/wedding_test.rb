require "test_helper"

class WeddingTest < ActiveSupport::TestCase
  test "normalizes and protects wedding addresses" do
    wedding = create_wedding(subdomain: " EDUARDO-AND-RAQUEL ")
    assert_equal "eduardo-and-raquel", wedding.subdomain
    duplicate = Wedding.new(wedding_attributes)
    assert_not duplicate.valid?
    assert duplicate.errors.added?(:subdomain, :taken, value: "eduardo-and-raquel")
    %w[app admin www a.b -bad bad- bad--address].each do |subdomain|
      wedding.subdomain = subdomain
      assert_not wedding.valid?, "#{subdomain} should not be allowed"
    end
  end

  test "RSVP deadline cannot follow the wedding date" do
    wedding = Wedding.new(wedding_attributes(rsvp_deadline: Date.current + 91.days))
    assert_not wedding.valid?
    assert_includes wedding.errors[:rsvp_deadline], "must be on or before the wedding date"
  end

  test "drafts and past weddings do not accept RSVPs" do
    wedding = create_wedding
    assert_not wedding.accepting_rsvps?
    wedding.published!
    assert wedding.accepting_rsvps?
    wedding.update!(rsvp_deadline: Date.yesterday)
    assert_not wedding.accepting_rsvps?
    wedding.update!(rsvp_deadline: nil, wedding_date: Date.yesterday)
    assert_not wedding.accepting_rsvps?
  end

  test "uploads reject unsafe image formats" do
    wedding = Wedding.new(wedding_attributes)
    wedding.cover_photo.attach(io: StringIO.new('<svg xmlns="http://www.w3.org/2000/svg"></svg>'), filename: "unsafe.svg", content_type: "image/svg+xml")
    assert_not wedding.valid?
    assert_includes wedding.errors[:base], "Photos must be JPEG, PNG, or WebP"
  end

  test "map URLs only allow full HTTPS addresses" do
    wedding = create_wedding
    event = wedding.events.new(title: "Ceremony", starts_at: Time.current, venue_name: "Garden", address: "Mexico City")
    ["javascript:alert(1)", "http://example.com", "https://user:pass@example.com"].each do |url|
      event.map_url = url
      assert_not event.valid?
    end
    event.map_url = "https://maps.google.com/?q=Mexico"
    assert event.valid?
    event.map_url = nil
    assert_includes event.map_link, "query=Garden%2C+Mexico+City"
  end

  test "guest emails are unique per wedding and party sizes are bounded" do
    wedding = create_wedding
    attrs = { guest_name: "Guest", email: " GUEST@example.com ", attendance: :attending, party_size: 2 }
    wedding.rsvps.create!(attrs)
    duplicate = wedding.rsvps.new(attrs.merge(email: "guest@example.com"))
    assert_not duplicate.valid?
    other = create_wedding(subdomain: "another-wedding")
    assert other.rsvps.new(attrs).valid?
    duplicate.email = "another@example.com"
    duplicate.party_size = 11
    assert_not duplicate.valid?
    duplicate.party_size = 1
    duplicate.attendance = "invalid"
    assert_not duplicate.valid?
  end

  test "map embed accepts Google copy HTML and rejects other iframe destinations" do
    event = create_wedding.events.new(title: "Ceremony", starts_at: Time.current, venue_name: "Garden")
    event.map_embed_url = '<iframe src="https://www.google.com/maps/embed?pb=venue&amp;hl=en" onload="alert(1)"></iframe><script>alert(1)</script>'
    assert event.valid?
    assert_equal "https://www.google.com/maps/embed?pb=venue&hl=en", event.map_embed_url
    ["javascript:alert(1)", "http://www.google.com/maps/embed?pb=venue", "https://www.google.com.attacker.example/maps/embed", "https://attacker.example/maps/embed", "https://www.google.com/maps/search?q=venue", "https://user:pass@www.google.com/maps/embed", "https://www.google.com:444/maps/embed"].each do |url|
      event.map_embed_url = url
      assert_not event.valid?, "#{url} must not be embeddable"
    end
  end
end
