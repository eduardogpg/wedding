require "test_helper"

class ScheduleAndTemplatesTest < ActionDispatch::IntegrationTest
  test "either ceremony or reception can be the only schedule event" do
    sign_in
    get new_wedding_path
    assert_select "[data-wedding-form-target='events'] [data-event-card]", count: 1

    %w[Ceremony Reception].each_with_index do |title, index|
      other = title == "Ceremony" ? "Reception" : "Ceremony"
      assert_difference "Event.count", 1 do
        post weddings_path, params: { wedding: wedding_attributes(subdomain: "one-event-#{index}", events_attributes: {
          "0" => { title: title, starts_at: "#{Date.current + 90.days}T18:00", venue_name: "The garden", show_map: "0" },
          "1" => { title: other, starts_at: "", venue_name: "", show_map: "1" }
        }) }
      end
      wedding = Wedding.last
      assert_redirected_to wedding_path(wedding)
      assert_equal [title], wedding.events.pluck(:title)
    end
  end

  test "a partially completed event still explains which details are missing" do
    sign_in
    assert_no_difference "Wedding.count" do
      post weddings_path, params: { wedding: wedding_attributes(events_attributes: {
        "0" => { title: "Reception", venue_name: "The garden", starts_at: "" }
      }) }
    end
    assert_response :unprocessable_entity
    assert_select ".error-summary", text: /#{Regexp.escape(I18n.t('errors.messages.blank'))}/
  end

  test "templates persist independently of palettes and render in preview and public pages" do
    sign_in
    wedding = create_wedding(status: :published)
    Wedding::PAGE_TEMPLATES.each_key do |template|
      patch wedding_path(wedding), params: { preview: "1", wedding: { page_template: template, theme: "rose" } }
      assert_redirected_to preview_wedding_path(wedding)
      assert_equal template, wedding.reload.page_template
      assert_equal "rose", wedding.theme
      follow_redirect!
      assert_response :success
      assert_select "body.page-template-#{template}.theme-rose"
      assert_select "#home h1", /Eduardo.*Raquel/m
      assert_select "#celebration"
      assert_select "#rsvp"
      host! "#{wedding.subdomain}.localhost"
      get "/"
      assert_response :success
      assert_select "body.page-template-#{template}"
      assert_select "#rsvp form"
      host! "app.localhost"
    end
    patch wedding_path(wedding), params: { wedding: { page_template: "../../secrets" } }
    assert_response :unprocessable_entity
    assert_select ".error-summary"
    assert_equal "classic", wedding.reload.page_template
  end

  test "a gallery photo also provides a cover in every template" do
    sign_in
    wedding = create_wedding
    wedding.gallery_photos.attach(file_fixture_upload("pixel.png", "image/png"))
    Wedding::PAGE_TEMPLATES.each_key do |template|
      wedding.update!(page_template: template)
      get preview_wedding_path(wedding)
      assert_response :success
      assert_select "#home .hero-photo", count: 1
      assert_select "#moments .carousel-slide img", count: 1
    end
  end
end
