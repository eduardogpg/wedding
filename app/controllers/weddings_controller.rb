class WeddingsController < PlannerController
  before_action :set_wedding, only: %i[show edit update destroy preview publish unpublish]
  around_action :use_wedding_timezone, only: %i[edit update]

  def index
    @weddings = Wedding.with_attached_cover_photo.chronological
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
    @wedding = Wedding.new(invitation_text: "With full hearts, we invite you to celebrate our wedding. Join us for a day of love, laughter, and memories we’ll treasure forever.")
    @wedding.events.build(title: "Ceremony")
    @wedding.events.build(title: "Reception")
  end

  def create
    @wedding = Wedding.new
    zone = params.dig(:wedding, :timezone).presence_in(ActiveSupport::TimeZone.all.map(&:name)) || "Mexico City"
    Time.use_zone(zone) do
      @wedding.assign_attributes(wedding_params)
      if @wedding.save
        redirect_to @wedding, notice: "Wedding created. Add your finishing touches, then publish when you’re ready."
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
      @wedding.gallery_photos = @wedding.gallery_photos.blobs.to_a + new_gallery
    end

    if @wedding.save
      remove_selected_photos
      redirect_to @wedding, notice: "Wedding details saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @wedding.destroy!
    redirect_to root_path, notice: "Wedding deleted."
  end

  def preview
    @preview = true
    @rsvp = @wedding.rsvps.new
    render "public_weddings/show", layout: "wedding"
  end

  def publish
    if @wedding.update(status: :published)
      redirect_to @wedding, notice: "The wedding page is live and ready to share."
    else
      redirect_to edit_wedding_path(@wedding), alert: @wedding.errors.full_messages.to_sentence
    end
  end

  def unpublish
    @wedding.update!(status: :draft)
    redirect_to @wedding, notice: "The wedding page is now private."
  end

  private

  def set_wedding
    @wedding = Wedding.find(params[:id])
  end

  def wedding_params
    params.require(:wedding).permit(:partner_one, :partner_two, :subdomain, :wedding_date,
      :timezone, :headline, :invitation_text, :story, :dress_code, :rsvp_deadline, :theme, :gallery_layout,
      :cover_photo, gallery_photos: [],
      events_attributes: [ :id, :title, :starts_at, :venue_name, :address, :map_url, :show_map, :map_embed_url, :notes, :position, :_destroy ])
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
