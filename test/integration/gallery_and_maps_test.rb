require "test_helper"

class GalleryAndMapsTest < ActionDispatch::IntegrationTest
  setup do
    @wedding = create_wedding(status: :published)
    @event = @wedding.events.create!(title: "Ceremony", venue_name: "Jardín", address: "San Miguel de Allende, Mexico", starts_at: Time.current)
  end

  test "gallery renders carousel controls and can switch to a grid" do
    sign_in
    patch wedding_path(@wedding), params: { wedding: {
      gallery_layout: "carousel", gallery_photos: [file_fixture_upload("pixel.png", "image/png"), file_fixture_upload("pixel.png", "image/png")]
    } }
    assert_redirected_to wedding_path(@wedding)
    assert_equal "carousel", @wedding.reload.gallery_layout
    get preview_wedding_path(@wedding)
    assert_response :success
    assert_select ".photo-carousel[data-controller='carousel']"
    assert_select ".carousel-slide", count: 2
    assert_select "button[aria-label='Previous photo'][disabled]"
    assert_select "button[aria-label='Next photo']"
    assert_select ".carousel-dot", count: 2
    assert_select ".carousel-counter", "Photo 1 of 2"

    patch wedding_path(@wedding), params: { wedding: { gallery_layout: "grid" } }
    assert_redirected_to wedding_path(@wedding)
    host! "#{@wedding.subdomain}.localhost"
    get "/"
    assert_response :success
    assert_select ".gallery-grid img", count: 2
    assert_select ".photo-carousel", count: 0
  end

  test "one photo needs no carousel navigation" do
    @wedding.gallery_photos.attach(file_fixture_upload("pixel.png", "image/png"))
    host! "#{@wedding.subdomain}.localhost"
    get "/"
    assert_response :success
    assert_select ".carousel-slide", count: 1
    assert_select ".carousel-controls", count: 0
  end

  test "planner can configure and hide an embedded Google map per event" do
    sign_in
    embed_url = "https://www.google.com/maps/embed?pb=example"
    patch wedding_path(@wedding), params: { wedding: { events_attributes: {
      "0" => { id: @event.id, show_map: "1", map_embed_url: "<iframe src=\"#{embed_url}\"></iframe>" }
    } } }
    assert_redirected_to wedding_path(@wedding)
    assert_equal embed_url, @event.reload.map_embed_url
    get preview_wedding_path(@wedding)
    assert_select "iframe[src=?][loading='lazy']", embed_url
    assert_select "iframe[title='Google Maps: Jardín']"

    patch wedding_path(@wedding), params: { wedding: { events_attributes: { "0" => { id: @event.id, show_map: "0" } } } }
    assert_redirected_to wedding_path(@wedding)
    assert_not @event.reload.show_map?
    host! "#{@wedding.subdomain}.localhost"
    get "/"
    assert_select ".venue-map iframe", count: 0
    assert_select ".guest-event a", "Open in Google Maps"
  end

  test "venue and address generate a map when no embed code is supplied" do
    host! "#{@wedding.subdomain}.localhost"
    get "/"
    assert_response :success
    assert_select ".venue-map iframe[src=?]", @event.google_maps_embed_url
    assert_includes @event.google_maps_embed_url, "output=embed"
    assert_includes @event.google_maps_embed_url, "San+Miguel+de+Allende"
  end

  test "untrusted iframe sources and unknown gallery layouts are rejected" do
    sign_in
    patch wedding_path(@wedding), params: { wedding: { gallery_layout: "unknown", events_attributes: {
      "0" => { id: @event.id, map_embed_url: '<iframe src="https://attacker.example/maps/embed"></iframe>' }
    } } }
    assert_response :unprocessable_entity
    assert_select ".error-summary", /Google Maps/
    assert_select ".error-summary", /Gallery layout/
    assert_nil @event.reload.map_embed_url
    assert_equal "carousel", @wedding.reload.gallery_layout
  end

  test "an otherwise blank added event is ignored despite the map checkbox" do
    sign_in
    assert_no_difference "Event.count" do
      patch wedding_path(@wedding), params: { wedding: { events_attributes: {
        "new" => { title: "", venue_name: "", starts_at: "", map_embed_url: "", show_map: "1" }
      } } }
    end
    assert_redirected_to wedding_path(@wedding)
  end
end
