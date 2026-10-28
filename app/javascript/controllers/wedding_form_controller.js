import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["events", "eventTemplate", "partnerOne", "partnerTwo", "subdomain"]

  connect() {
    this.subdomainEdited = this.subdomainTarget.dataset.autoSuggest !== "true"
    this.nextEvent = 0
  }

  suggestSubdomain() {
    if (this.subdomainEdited) return
    const slug = value => value.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")
    this.subdomainTarget.value = [slug(this.partnerOneTarget.value), slug(this.partnerTwoTarget.value)].filter(Boolean).join("-and-").slice(0, 63).replace(/-$/, "")
  }

  markSubdomainEdited() { this.subdomainEdited = true }

  addEvent() {
    const key = `new_${Date.now()}_${this.nextEvent++}`
    this.eventsTarget.insertAdjacentHTML("beforeend", this.eventTemplateTarget.innerHTML.replaceAll("NEW_EVENT", key))
    this.eventsTarget.lastElementChild.querySelector('input[type="text"]').focus()
  }

  removeEvent(event) {
    const card = event.currentTarget.closest("[data-event-card]")
    card.querySelector("[data-destroy-field]").value = "1"
    card.hidden = true
    card.querySelectorAll("input:not([type=hidden]), textarea").forEach(input => input.required = false)
  }
}
