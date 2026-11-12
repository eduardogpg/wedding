import { Controller } from "@hotwired/stimulus"

// Before the celebration, selected files and wishes stay in memory.
// Once the party page is open, persist=true sends them to the wedding.
export default class extends Controller {
  static targets = ["photosDialog", "wishesDialog", "photoForm", "photoDone", "photoInput", "cameraInput", "photoError", "photoPreviews", "photoCount", "photoSubmit", "photoResult", "wishForm", "wishDone", "wishName", "wishMessage", "wishCount", "wishResult", "wishSignature", "wishError"]
  static values = { persist: { type: Boolean, default: false }, wishUrl: String, photoUrl: String }

  connect() { this.photos = [] }
  disconnect() { this.photos.forEach(photo => URL.revokeObjectURL(photo.url)) }

  openPhotos() {
    this.photoFormTarget.hidden = false
    this.photoDoneTarget.hidden = true
    this.photosDialogTarget.showModal()
  }

  closePhotos() { this.photosDialogTarget.close() }
  choosePhotos() { this.photoInputTarget.click() }
  takePhoto() { this.cameraInputTarget.click() }

  closeBackdrop(event) {
    if (event.target === event.currentTarget) event.currentTarget.close()
  }

  selectPhotos(event) {
    const files = Array.from(event.currentTarget.files)
    event.currentTarget.value = ""
    if (files.length === 0) return
    let error = ""
    if (files.some(file => !["image/jpeg", "image/png", "image/webp"].includes(file.type))) error = "Elige fotos en formato JPG, PNG o WebP."
    else if (files.some(file => file.size > 10 * 1024 * 1024)) error = "Cada foto debe pesar 10 MB o menos."
    else if (this.photos.length + files.length > 10) error = "Puedes elegir hasta 10 fotos por envío."
    this.photoErrorTarget.textContent = error
    this.photoErrorTarget.hidden = !error
    if (error) return
    this.photos.push(...files.map(file => ({ file, url: URL.createObjectURL(file) })))
    this.renderPhotos()
  }

  renderPhotos() {
    this.photoPreviewsTarget.replaceChildren()
    this.photos.forEach((photo, index) => {
      const tile = document.createElement("div")
      tile.className = "live-photo-tile"
      const image = document.createElement("img")
      image.src = photo.url
      image.alt = `Vista previa: ${photo.file.name}`
      const remove = document.createElement("button")
      remove.type = "button"
      remove.textContent = "×"
      remove.dataset.index = index
      remove.dataset.action = "live-event#removePhoto"
      remove.setAttribute("aria-label", `Quitar foto ${index + 1}`)
      tile.append(image, remove)
      this.photoPreviewsTarget.append(tile)
    })
    this.photoCountTarget.textContent = this.photos.length ? `${this.photos.length} ${this.photos.length === 1 ? "foto seleccionada" : "fotos seleccionadas"}` : "Todavía no has elegido fotos."
    this.photoSubmitTarget.disabled = this.photos.length === 0
  }

  removePhoto(event) {
    const [photo] = this.photos.splice(Number(event.currentTarget.dataset.index), 1)
    URL.revokeObjectURL(photo.url)
    this.photoErrorTarget.hidden = true
    this.renderPhotos()
  }

  async sharePhotos(event) {
    event.preventDefault()
    if (this.photos.length === 0) return
    if (!this.persistValue) {
      this.photoResultTarget.textContent = `Así se verá la confirmación para ${this.photos.length} ${this.photos.length === 1 ? "foto seleccionada" : "fotos seleccionadas"}.`
      this.showConfirmation(this.photoFormTarget, this.photoDoneTarget)
      return
    }

    const body = new FormData(this.photoFormTarget)
    this.photos.forEach((photo) => body.append("guest_photo[images][]", photo.file, photo.file.name))
    this.photoErrorTarget.hidden = true
    this.photoSubmitTarget.disabled = true
    try {
      const payload = await this.post(this.photoUrlValue, body)
      const count = Number(payload.count) || this.photos.length
      this.photoResultTarget.textContent = count === 1 ? "Tu foto ya está con los novios." : `Tus ${count} fotos ya están con los novios.`
      this.showConfirmation(this.photoFormTarget, this.photoDoneTarget)
    } catch (error) {
      this.photoErrorTarget.textContent = error.message
      this.photoErrorTarget.hidden = false
      this.photoSubmitTarget.disabled = false
    }
  }

  clearPhotos() {
    this.photos.forEach(photo => URL.revokeObjectURL(photo.url))
    this.photos = []
    this.photoFormTarget.reset()
    this.photoErrorTarget.hidden = true
    this.renderPhotos()
  }

  openWishes() {
    this.wishFormTarget.hidden = false
    this.wishDoneTarget.hidden = true
    this.wishFormTarget.reset()
    this.wishMessageTarget.setCustomValidity("")
    this.updateWishCount()
    this.wishesDialogTarget.showModal()
  }

  closeWishes() { this.wishesDialogTarget.close() }

  updateWishCount() {
    this.wishMessageTarget.setCustomValidity("")
    this.wishCountTarget.textContent = `${this.wishMessageTarget.value.length} / 1000`
  }

  async shareWish(event) {
    event.preventDefault()
    const message = this.wishMessageTarget.value.trim()
    if (!message) {
      this.wishMessageTarget.setCustomValidity("Escribe unas palabras para los novios.")
      this.wishMessageTarget.reportValidity()
      return
    }
    if (!this.persistValue) {
      this.wishResultTarget.textContent = message
      this.wishSignatureTarget.textContent = this.wishNameTarget.value.trim() || "Con mucho cariño"
      this.showConfirmation(this.wishFormTarget, this.wishDoneTarget)
      return
    }

    this.wishErrorTarget.hidden = true
    try {
      const body = new FormData()
      body.append("guest_wish[guest_name]", this.wishNameTarget.value.trim())
      body.append("guest_wish[body]", message)
      const payload = await this.post(this.wishUrlValue, body)
      this.wishResultTarget.textContent = payload.body || message
      this.wishSignatureTarget.textContent = payload.guest_name || "Con mucho cariño"
      this.showConfirmation(this.wishFormTarget, this.wishDoneTarget)
    } catch (error) {
      this.wishErrorTarget.textContent = error.message
      this.wishErrorTarget.hidden = false
    }
  }

  showConfirmation(form, confirmation) {
    form.hidden = true
    confirmation.hidden = false
    this.focusConfirmation(confirmation)
  }

  async post(url, body) {
    if (!url) throw new Error("No pudimos guardar esto. Vuelve a abrir la página de la fiesta.")
    const token = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")
    let response
    try {
      response = await fetch(url, {
        method: "POST",
        headers: { "X-CSRF-Token": token, Accept: "application/json" },
        body
      })
    } catch (_error) {
      throw new Error("No pudimos enviar esto. Revisa la conexión e inténtalo de nuevo.")
    }
    const payload = await response.json().catch(() => ({}))
    if (!response.ok) throw new Error(payload.error || "No pudimos guardar esto. Inténtalo de nuevo.")
    return payload
  }

  focusConfirmation(section) {
    section.setAttribute("tabindex", "-1")
    section.focus()
  }
}
