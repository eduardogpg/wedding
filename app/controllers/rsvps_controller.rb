require "csv"

class RsvpsController < PlannerController
  def index
    wedding = Wedding.find(params[:wedding_id])
    csv = CSV.generate do |rows|
      rows << [ "Nombre", "Correo", "Respuesta", "Personas", "Mensaje", "Recibido (UTC)" ]
      wedding.rsvps.order(:created_at).find_each do |rsvp|
        rows << [ rsvp.guest_name, rsvp.email, rsvp.attending? ? "Asiste" : "No asiste", rsvp.party_size, rsvp.message, rsvp.created_at.iso8601 ].map { |value| csv_safe(value) }
      end
    end
    send_data csv, filename: "#{wedding.subdomain}-rsvps.csv", type: "text/csv", disposition: "attachment"
  end

  private

  # Prevent spreadsheet applications from interpreting guest-entered values as formulas.
  def csv_safe(value)
    value.is_a?(String) && value.match?(/\A[\s]*[=+@-]/) ? "'#{value}" : value
  end
end
