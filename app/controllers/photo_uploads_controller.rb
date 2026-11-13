class PhotoUploadsController < PlannerController
  include ActiveStorage::SetCurrent

  def create
    attributes = params.require(:blob).permit(:filename, :byte_size, :checksum, :content_type).to_h.symbolize_keys
    unless Wedding::PHOTO_TYPES.include?(attributes[:content_type]) && attributes[:byte_size].to_i.between?(1, Wedding::MAX_PHOTO_SIZE)
      render json: { error: "Elige una foto JPEG, PNG o WebP de hasta 10 MB." }, status: :unprocessable_entity
      return
    end

    blob = ActiveStorage::Blob.create_before_direct_upload!(**attributes)
    render json: blob.as_json(root: false, methods: :signed_id).merge(direct_upload: {
      url: blob.service_url_for_direct_upload,
      headers: blob.service_headers_for_direct_upload
    })
  end
end
