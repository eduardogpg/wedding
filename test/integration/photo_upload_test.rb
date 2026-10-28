require "test_helper"

class PhotoUploadTest < ActionDispatch::IntegrationTest
  test "planner can upload append preview and remove wedding photos" do
    sign_in
    wedding = create_wedding
    patch wedding_path(wedding), params: { wedding: {
      cover_photo: file_fixture_upload("pixel.png", "image/png"),
      gallery_photos: [file_fixture_upload("pixel.png", "image/png")]
    } }
    assert_redirected_to wedding_path(wedding)
    assert wedding.reload.cover_photo.attached?
    assert wedding.cover_photo.variant(resize_to_limit: [600, 400]).processed
    assert_equal 1, wedding.gallery_photos.count
    original_cover_id = wedding.cover_photo.blob.id

    patch wedding_path(wedding), params: { wedding: {
      headline: "A day to remember", cover_photo: "",
      gallery_photos: [file_fixture_upload("pixel.png", "image/png")]
    } }
    assert_redirected_to wedding_path(wedding)
    assert_equal original_cover_id, wedding.reload.cover_photo.blob.id
    assert_equal 2, wedding.gallery_photos.count
    get preview_wedding_path(wedding)
    assert_response :success
    assert_select ".hero-photo"
    assert_select ".guest-gallery img", count: 2
    get edit_wedding_path(wedding)
    assert_response :success
    assert_select ".photo-edit-grid img", count: 2

    patch wedding_path(wedding), params: { wedding: {
      remove_cover_photo: "1", remove_gallery_photo_ids: [wedding.gallery_photos.first.id]
    } }
    assert_redirected_to wedding_path(wedding)
    assert_not wedding.reload.cover_photo.attached?
    assert_equal 1, wedding.gallery_photos.count
  end
end
