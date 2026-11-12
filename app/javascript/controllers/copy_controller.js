import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.textValue)
      this.element.querySelector("[data-copy-label]").textContent = "Enlace copiado"
    } catch {
      window.prompt("Copia este enlace de la boda:", this.textValue)
    }
  }
}
