class PublicWeddingsController < ApplicationController
  layout "wedding"
  before_action :set_wedding
  rate_limit to: 8, within: 1.minute, only: :respond,
    with: -> { redirect_to guest_root_path(anchor: "rsvp"), alert: "Please wait a minute before trying again." }

  def show
    @rsvp = @wedding.rsvps.new
  end

  def live
    @live_mock = true
  end

  def respond
    unless @wedding.accepting_rsvps?
      redirect_to guest_root_path(anchor: "rsvp"), alert: "RSVPs are now closed. Please contact the couple or planner."
      return
    end

    @rsvp = @wedding.rsvps.new(params.require(:rsvp).permit(:guest_name, :email, :attendance, :party_size, :message))
    if @rsvp.save
      redirect_to guest_root_path(anchor: "rsvp"), notice: "Thank you, #{@rsvp.guest_name}! Your response has been received."
    else
      render :show, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    @rsvp.errors.add(:email, "has already responded to this wedding")
    render :show, status: :unprocessable_entity
  end

  private

  def set_wedding
    domain = Rails.configuration.x.app_domain
    subdomain = request.host.delete_suffix(".#{domain}")
    @wedding = Wedding.published.find_by!(subdomain: subdomain)
  end
end
