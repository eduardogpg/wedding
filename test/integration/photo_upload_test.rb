require "test_helper"

class PhotoUploadTest < ActionDispatch::IntegrationTest
  test "photo uploads require a planner and enforce photo limits before storing metadata" do
    host! "app.localhost"
    post photo_uploads_path, params: { blob: upload_metadata }
    assert_redirected_to new_session_path
    sign_in
    [ { content_type: "image/svg+xml" }, { byte_size: Wedding::MAX_PHOTO_SIZE + 1 }, { byte_size: 0 } ].each do |invalid|
      assert_no_difference "ActiveStorage::Blob.count" do
        post photo_uploads_path, params: { blob: upload_metadata.merge(invalid) }, as: :json
      end
      assert_response :unprocessable_entity
    end
    host! "eduardo-and-raquel.localhost"
    post "/photo_uploads", params: { blob: upload_metadata }, as: :json
    assert_response :not_found
  end

  test "directly uploaded photos survive validation errors and can be saved and viewed" do
    sign_in
    cover = directly_upload_photo
    gallery = directly_upload_photo
    attributes = wedding_attributes(subdomain: "app", cover_photo: cover, gallery_photos: [gallery])
    assert_no_difference "Wedding.count" do
      post weddings_path, params: { wedding: attributes }
    end
    assert_response :unprocessable_entity
    assert_select 'input[type="hidden"][name="wedding[cover_photo]"][value=?]', cover
    assert_select 'input[type="hidden"][name="wedding[gallery_photos][]"][value=?]', gallery
    assert_select ".pending-photo img", count: 2

    post weddings_path, params: { preview: "1", wedding: attributes.merge(subdomain: "retained-photos") }
    wedding = Wedding.last
    assert_redirected_to preview_wedding_path(wedding)
    assert_equal ActiveStorage::Blob.find_signed!(cover), wedding.cover_photo.blob
    assert_equal [ActiveStorage::Blob.find_signed!(gallery).id], wedding.gallery_photos.blobs.pluck(:id)
    follow_redirect!
    assert_select "#home .hero-photo"
    assert_select ".guest-gallery img", count: 1
    get rails_blob_path(wedding.cover_photo, only_path: true)
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_equal file_fixture("pixel.png").binread, response.body

    extra = directly_upload_photo
    2.times do
      patch wedding_path(wedding), params: { wedding: { partner_one: "", gallery_photos: [extra] } }
      assert_response :unprocessable_entity
      assert_select 'input[type="hidden"][name="wedding[gallery_photos][]"][value=?]', extra
      assert_equal 1, wedding.reload.gallery_photos.count
    end
    patch wedding_path(wedding), params: { wedding: { partner_one: "Eduardo", gallery_photos: [extra] } }
    assert_redirected_to wedding_path(wedding)
    assert_equal 2, wedding.reload.gallery_photos.count
    patch wedding_path(wedding), params: { wedding: { gallery_photos: [extra] } }
    assert_redirected_to wedding_path(wedding)
    assert_equal 2, wedding.reload.gallery_photos.count
  end

  test "several carousel photos are saved from one request" do
    sign_in
    wedding = create_wedding
    patch wedding_path(wedding), params: { wedding: { gallery_photos: [
      file_fixture_upload("pixel.png", "image/png"),
      file_fixture_upload("pixel.png", "image/png"),
      file_fixture_upload("pixel.png", "image/png")
    ] } }
    assert_redirected_to wedding_path(wedding)
    assert_equal 3, wedding.reload.gallery_photos.count
  end

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

  private

  def upload_metadata
    bytes = file_fixture("pixel.png").binread
    { filename: "pixel.png", byte_size: bytes.bytesize, checksum: Digest::MD5.base64digest(bytes), content_type: "image/png" }
  end

  def directly_upload_photo
    post photo_uploads_path, params: { blob: upload_metadata }, as: :json
    assert_response :success
    data = response.parsed_body
    assert ActiveStorage::Blob.find_signed!(data.fetch("signed_id"))
    upload = data.fetch("direct_upload")
    put URI(upload.fetch("url")).request_uri, params: file_fixture("pixel.png").binread, headers: upload.fetch("headers")
    assert_response :no_content
    data.fetch("signed_id")
  end
end
