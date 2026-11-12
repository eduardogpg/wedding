class WeddingsController < PlannerController
  before_action :set_wedding, only: %i[show edit update destroy preview publish unpublish]
  around_action :use_wedding_timezone, only: %i[edit update]

  def index
    @weddings = Wedding.with_attached_cover_photo.with_attached_gallery_photos.chronological
    @query = params[:q].to_s.strip.first(100)
    if @query.present?
      pattern = "%#{Wedding.sanitize_sql_like(@query)}%"
      @weddings = @weddings.where("partner_one ILIKE :query OR partner_two ILIKE :query OR subdomain ILIKE :query", query: pattern)
    end
    @filter = params[:status].presence_in(%w[all published draft]) || "all"
    @weddings = @weddings.where(status: @filter) unless @filter == "all"
    @total = Wedding.count
    @published = Wedding.published.count
    @upcoming = Wedding.upcoming.count
    @next_wedding = Wedding.upcoming.chronological.first
  end

  def show
    @rsvps = @wedding.rsvps.order(created_at: :desc)
  end

  def new
    @wedding = Wedding.new(invitation_text: "Con todo el corazón, te invitamos a celebrar nuestra boda. Acompáñanos en un día de amor, risas y recuerdos que vamos a guardar para siempre.")
    @wedding.events.build
  end

  def create
    @wedding = Wedding.new
    zone = params.dig(:wedding, :timezone).presence_in(ActiveSupport::TimeZone.all.map(&:name)) || "Mexico City"
    Time.use_zone(zone) do
      @wedding.assign_attributes(wedding_params)
      if @wedding.save
        redirect_to saved_wedding_path, notice: "Boda creada. Agrega los últimos detalles y publícala cuando esté lista."
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  def edit
  end

  def update
    attributes = wedding_params.to_h
    attributes.delete("cover_photo") if attributes["cover_photo"].blank?
    new_gallery = attributes.delete("gallery_photos")&.reject(&:blank?)
    @wedding.assign_attributes(attributes)
    if new_gallery.present?
      uploads = new_gallery.map { |photo| photo.is_a?(String) ? ActiveStorage::Blob.find_signed!(photo) : photo }
      @wedding.gallery_photos = (@wedding.gallery_photos.blobs.to_a + uploads).uniq
    end

    if @wedding.save
      remove_selected_photos
      redirect_to saved_wedding_path, notice: "Los detalles de la boda quedaron guardados."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @wedding.destroy!
    redirect_to root_path, notice: "Boda eliminada."
  end

  def preview
    @preview = true
    phase = params[:phase].presence_in(%w[live invitation])
    if phase == "live" || (phase != "invitation" && @wedding.celebration_open?)
      @live = true
      @live_mock = true
      render "public_weddings/live", layout: "wedding"
    else
      @rsvp = @wedding.rsvps.new
      render "public_weddings/show", layout: "wedding"
    end
  end

  def publish
    if @wedding.update(status: :published)
      redirect_to @wedding, notice: "La página ya está publicada y lista para compartir."
    else
      redirect_to edit_wedding_path(@wedding), alert: @wedding.errors.full_messages.to_sentence
    end
  end

  def unpublish
    @wedding.update!(status: :draft)
    redirect_to @wedding, notice: "La página de la boda ahora es privada."
  end

  private

  def set_wedding
    @wedding = Wedding.find(params[:id])
  end

  def wedding_params
    params.require(:wedding).permit(:partner_one, :partner_two, :subdomain, :wedding_date,
      :timezone, :headline, :invitation_text, :story, :dress_code, :rsvp_deadline, :theme, :gallery_layout, :page_template,
      :celebration_starts_at, :landing_mode,
      :cover_photo, gallery_photos: [],
      events_attributes: [ :id, :title, :starts_at, :venue_name, :address, :map_url, :show_map, :map_embed_url, :notes, :position, :_destroy ],
      gift_registries_attributes: [ :id, :store_name, :url, :_destroy ],
      faqs_attributes: [ :id, :question, :answer, :visible, :_destroy ])
  end

  def saved_wedding_path
    params[:preview] == "1" ? preview_wedding_path(@wedding) : wedding_path(@wedding)
  end

  def use_wedding_timezone(&action)
    zone = params.dig(:wedding, :timezone).presence || @wedding.timezone
    Time.use_zone(zone.presence_in(ActiveSupport::TimeZone.all.map(&:name)) || "Mexico City", &action)
  end

  def remove_selected_photos
    @wedding.cover_photo.purge if params.dig(:wedding, :remove_cover_photo) == "1" && params.dig(:wedding, :cover_photo).blank?
    ids = Array(params.dig(:wedding, :remove_gallery_photo_ids)).map(&:to_s)
    @wedding.gallery_photos.attachments.where(id: ids).each(&:purge)
  end
end
