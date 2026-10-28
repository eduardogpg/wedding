require "test_helper"

class PlannerFlowTest < ActionDispatch::IntegrationTest
  test "planner pages require sign in" do
    host! "app.localhost"
    get root_path
    assert_redirected_to new_session_path
    wedding = create_wedding
    get preview_wedding_path(wedding)
    assert_redirected_to new_session_path
  end

  test "sign in renders dashboard and sign out removes access" do
    sign_in
    get root_path
    assert_response :success
    assert_select "h1", /Beautiful days start here/
    delete session_path
    get root_path
    assert_redirected_to new_session_path
  end

  test "planner creates edits publishes and unpublishes a wedding" do
    sign_in
    get new_wedding_path
    assert_response :success
    assert_difference "Wedding.count", 1 do
      assert_difference "Event.count", 1 do
        post weddings_path, params: { wedding: wedding_attributes(events_attributes: {
          "0" => { title: "Ceremony", starts_at: "#{Date.current + 90.days}T16:00", venue_name: "Garden" }
        }) }
      end
    end
    wedding = Wedding.last
    assert wedding.draft?
    assert_equal 16, wedding.events.first.starts_at.in_time_zone("Mexico City").hour
    get wedding_path(wedding)
    assert_response :success
    get edit_wedding_path(wedding)
    assert_response :success
    patch wedding_path(wedding), params: { wedding: { headline: "Our beautiful day" } }
    assert_redirected_to wedding_path(wedding)
    assert_equal "Our beautiful day", wedding.reload.headline
    get preview_wedding_path(wedding)
    assert_response :success
    assert_select ".preview-banner", /Planner preview/
    patch publish_wedding_path(wedding)
    assert wedding.reload.published?
    patch unpublish_wedding_path(wedding)
    assert wedding.reload.draft?
  end

  test "invalid weddings render useful errors" do
    sign_in
    assert_no_difference "Wedding.count" do
      post weddings_path, params: { wedding: wedding_attributes(partner_one: "", subdomain: "app") }
    end
    assert_response :unprocessable_entity
    assert_select ".error-summary", /reserved/
  end

  test "search and publication filters render only matching weddings" do
    sign_in
    published = create_wedding(status: :published)
    create_wedding(partner_one: "Sofia", subdomain: "sofia-and-daniel")
    get root_path, params: { q: "eduardo", status: "published" }
    assert_response :success
    assert_select ".wedding-card", count: 1
    assert_select ".wedding-card h3", published.couple_names
  end

  test "nested updates cannot edit another wedding event" do
    sign_in
    wedding = create_wedding
    other = create_wedding(subdomain: "someone-else")
    event = other.events.create!(title: "Private event", venue_name: "Elsewhere", starts_at: Time.current)
    patch wedding_path(wedding), params: { wedding: { events_attributes: { "0" => { id: event.id, title: "Changed" } } } }
    assert_response :not_found
    assert_equal "Private event", event.reload.title
  end

  test "RSVP export protects guest spreadsheet values" do
    sign_in
    wedding = create_wedding
    wedding.rsvps.create!(guest_name: "=HYPERLINK(1)", email: "guest@example.com", attendance: :attending, party_size: 2, message: "+malicious")
    get wedding_rsvps_path(wedding, format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.body, "'=HYPERLINK(1)"
    assert_includes response.body, "'+malicious"
  end
end
