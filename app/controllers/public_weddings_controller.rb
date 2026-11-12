class PublicWeddingsController < ApplicationController
  layout "wedding"
  before_action :set_wedding
  rate_limit to: 8, within: 1.minute, only: %i[respond create_wish create_photos],
    with: -> { redirect_to guest_root_path(anchor: ("rsvp" if action_name == "respond")), alert: "Espera un minuto antes de volver a intentarlo." }

  def show
    if @wedding.celebration_open?
      assign_live_page
      render :live
    else
      @rsvp = @wedding.rsvps.new
    end
  end

  def invitation
    @rsvp = @wedding.rsvps.new
    render :show
  end

  def live
    assign_live_page(mock: !@wedding.celebration_open?)
  end

  def respond
    unless @wedding.accepting_rsvps?
      redirect_to invitation_return_path, alert: "Las confirmaciones ya cerraron. Escribe a la pareja o al planner."
      return
    end

    @rsvp = @wedding.rsvps.new(params.require(:rsvp).permit(:guest_name, :email, :attendance, :party_size, :message))
    if @rsvp.save
      redirect_to invitation_return_path, notice: "Gracias, #{@rsvp.guest_name}. Recibimos tu respuesta."
    else
      render :show, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    @rsvp.errors.add(:email, "ya respondió a esta boda")
    render :show, status: :unprocessable_entity
  end

  def create_wish
    return unless ensure_celebration_open!

    @guest_wish = @wedding.guest_wishes.new(guest_wish_params)
    if @guest_wish.save
      payload = { body: @guest_wish.body, guest_name: @guest_wish.guest_name.presence || "Con mucho cariño" }
      respond_to do |format|
        format.json { render json: payload }
        format.html { redirect_to guest_root_path, notice: "Tus buenos deseos ya están con #{@wedding.couple_names}." }
      end
    else
      message = @guest_wish.errors.full_messages.to_sentence
      respond_to do |format|
        format.json { render json: { error: message }, status: :unprocessable_entity }
        format.html { redirect_to guest_root_path, alert: message }
      end
    end
  end

  def create_photos
    return unless ensure_celebration_open!

    @guest_photo = @wedding.guest_photos.new(guest_photo_params)
    if @guest_photo.save
      respond_to do |format|
        format.json { render json: { count: @guest_photo.images.count } }
        format.html { redirect_to guest_root_path, notice: "Tus fotos ya son parte de la celebración." }
      end
    else
      message = @guest_photo.errors.full_messages.to_sentence
      respond_to do |format|
        format.json { render json: { error: message }, status: :unprocessable_entity }
        format.html { redirect_to guest_root_path, alert: message }
      end
    end
  end

  private

  def set_wedding
    domain = Rails.configuration.x.app_domain
    subdomain = request.host.delete_suffix(".#{domain}")
    @wedding = Wedding.published.find_by!(subdomain: subdomain)
  end

  def assign_live_page(mock: false)
    @live = true
    @live_mock = mock
  end

  def ensure_celebration_open!
    return true if @wedding.celebration_open?

    message = "La página de la fiesta se abre cuando comienza la celebración."
    respond_to do |format|
      format.json { render json: { error: message }, status: :forbidden }
      format.html { redirect_to guest_root_path, alert: message }
    end
    false
  end

  def invitation_return_path
    @wedding.celebration_open? ? guest_invitation_path(anchor: "rsvp") : guest_root_path(anchor: "rsvp")
  end

  def guest_wish_params
    params.require(:guest_wish).permit(:guest_name, :body)
  end

  def guest_photo_params
    params.require(:guest_photo).permit(:guest_name, :caption, images: [])
  end
end
