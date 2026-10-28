require "test_helper"

class PublicWeddingTest < ActionDispatch::IntegrationTest
  setup do
    @wedding = create_wedding(status: :published)
    host! "#{@wedding.subdomain}.localhost"
  end

  test "published wedding renders on its own subdomain" do
    get "/"
    assert_response :success
    assert_select "h1", /Eduardo/
    assert_select "form[action='/rsvp']"
    assert_select ".sidebar", count: 0
  end

  test "unpublished and unknown weddings return not found" do
    @wedding.draft!
    get "/"
    assert_response :not_found
    host! "unknown.localhost"
    get "/"
    assert_response :not_found
  end

  test "wedding hosts do not expose planner routes or login" do
    get "/weddings/#{@wedding.id}/edit"
    assert_response :not_found
    get "/session/new"
    assert_response :not_found
  end

  test "guest can RSVP without an account and duplicate responses are rejected" do
    params = { rsvp: { guest_name: "Our guest", email: "guest@example.com", attendance: "attending", party_size: 2, message: "Can’t wait!" } }
    assert_difference "Rsvp.count", 1 do
      post "/rsvp", params: params
    end
    assert_redirected_to "/#rsvp"
    assert_equal 2, @wedding.confirmed_guests
    assert_no_difference "Rsvp.count" do
      post "/rsvp", params: params
    end
    assert_response :unprocessable_entity
    assert_select ".error-summary", /already responded/
  end

  test "closed RSVPs cannot be submitted by posting directly" do
    @wedding.update!(rsvp_deadline: Date.yesterday)
    assert_no_difference "Rsvp.count" do
      post "/rsvp", params: { rsvp: { guest_name: "Late guest", email: "late@example.com", attendance: "attending", party_size: 1 } }
    end
    assert_redirected_to "/#rsvp"
    get "/"
    assert_select "form[action='/rsvp']", count: 0
  end

  test "guest response is scoped to the wedding subdomain" do
    other = create_wedding(subdomain: "another-couple", status: :published)
    post "/rsvp", params: { rsvp: { wedding_id: other.id, guest_name: "Our guest", email: "guest@example.com", attendance: "declined", party_size: 1 } }
    assert_equal 1, @wedding.rsvps.count
    assert_equal 0, other.rsvps.count
  end
end
