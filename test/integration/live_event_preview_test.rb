require "test_helper"

class LiveEventPreviewTest < ActionDispatch::IntegrationTest
  test "live mock is available for published weddings and respects draft privacy" do
    wedding = create_wedding(status: :published)
    host! "#{wedding.subdomain}.localhost"
    get "/fiesta"
    assert_response :success
    assert_select "html[lang='es']"
    assert_select "button[aria-controls='live-photo-dialog']"
    assert_select "button[aria-controls='live-wish-dialog']"
    assert_select "form[method='dialog']", count: 2
    wedding.draft!
    get "/fiesta"
    assert_response :not_found
  end

  test "draft live preview requires planner sign in" do
    wedding = create_wedding
    host! "app.localhost"
    get preview_wedding_path(wedding, phase: "live")
    assert_redirected_to new_session_path
    sign_in
    get preview_wedding_path(wedding, phase: "live")
    assert_response :success
    assert_select ".live-demo-banner"
    assert_select "a[href=?]", preview_wedding_path(wedding)
  end
end
