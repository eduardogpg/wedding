import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["faqs", "faqTemplate", "events", "eventTemplate", "registries", "registryTemplate", "partnerOne", "partnerTwo", "subdomain"]

  connect() {
    this.subdomainEdited = this.subdomainTarget.dataset.autoSuggest !== "true"
    this.nextIndex = Date.now()
  }

  suggestSubdomain() {
    if (this.subdomainEdited) return
    const slug = value => value.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")
    this.subdomainTarget.value = [slug(this.partnerOneTarget.value), slug(this.partnerTwoTarget.value)].filter(Boolean).join("-and-").slice(0, 63).replace(/-$/, "")
  }

  markSubdomainEdited() { this.subdomainEdited = true }

  addEvent() {
    const key = this.nextKey()
    this.eventsTarget.insertAdjacentHTML("beforeend", this.eventTemplateTarget.innerHTML.replaceAll("NEW_EVENT", key))
    this.eventsTarget.lastElementChild.querySelector('input[type="text"]').focus()
  }

  removeEvent(event) {
    this.removeCard(event.currentTarget.closest("[data-event-card]"))
  }

  addRegistry() {
    const key = this.nextKey()
    this.registriesTarget.insertAdjacentHTML("beforeend", this.registryTemplateTarget.innerHTML.replaceAll("NEW_REGISTRY", key))
    this.registriesTarget.lastElementChild.querySelector("input[type='text']").focus()
  }

  removeRegistry(event) {
    this.removeCard(event.currentTarget.closest("[data-registry-card]"))
  }

  addFaq() {
    const key = this.nextKey()
    this.faqsTarget.insertAdjacentHTML("beforeend", this.faqTemplateTarget.innerHTML.replaceAll("NEW_FAQ", key))
    this.faqsTarget.lastElementChild.querySelector("input[type=text]").focus()
  }

  nextKey() {
    this.nextIndex += 1
    return String(this.nextIndex)
  }

  removeFaq(event) {
    this.removeCard(event.currentTarget.closest("[data-faq-card]"))
  }

  removeCard(card) {
    card.querySelector("[data-destroy-field]").value = "1"
    card.hidden = true
    card.querySelectorAll("input:not([type=hidden]), textarea").forEach(input => input.required = false)
  }
}
