import { Controller } from "@hotwired/stimulus"

// Interactive mock only. All selected files and wishes stay in this controller's
// memory. No upload, request, browser storage, or persistence is performed.
export default class extends Controller {
  static targets = ["photosDialog", "wishesDialog", "photoForm", "photoDone", "photoInput", "cameraInput", "photoError", "photoPreviews", "photoCount", "photoSubmit", "photoResult", "wishForm", "wishDone", "wishName", "wishMessage", "wishCount", "wishResult", "wishSignature"]

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
    else if (this.photos.length + files.length > 10) error = "Puedes elegir hasta 10 fotos por envío de prueba."
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

  sharePhotos(event) {
    event.preventDefault()
    if (this.photos.length === 0) return
    this.photoResultTarget.textContent = `Así se verá la confirmación para ${this.photos.length} ${this.photos.length === 1 ? "foto seleccionada" : "fotos seleccionadas"}.`
    this.photoFormTarget.hidden = true
    this.photoDoneTarget.hidden = false
    this.focusConfirmation(this.photoDoneTarget)
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

  shareWish(event) {
    event.preventDefault()
    const message = this.wishMessageTarget.value.trim()
    if (!message) {
      this.wishMessageTarget.setCustomValidity("Escribe unas palabras para los novios.")
      this.wishMessageTarget.reportValidity()
      return
    }
    this.wishResultTarget.textContent = message
    this.wishSignatureTarget.textContent = this.wishNameTarget.value.trim() || "Con mucho cariño"
    this.wishFormTarget.hidden = true
    this.wishDoneTarget.hidden = false
    this.focusConfirmation(this.wishDoneTarget)
  }

  focusConfirmation(section) {
    section.setAttribute("tabindex", "-1")
    section.focus()
  }
}
