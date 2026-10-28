import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.textValue)
      this.element.querySelector("[data-copy-label]").textContent = "Link copied!"
    } catch {
      window.prompt("Copy this wedding link:", this.textValue)
    }
  }
}
