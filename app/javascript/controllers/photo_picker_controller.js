import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "previews", "status"]
  static values = { max: Number, existing: { type: Number, default: 0 }, multiple: { type: Boolean, default: false } }

  connect() {
    this.files = []
    this.urls = []
    this.ignoreChange = false
  }

  disconnect() {
    this.urls.forEach(url => URL.revokeObjectURL(url))
  }

  browse() {
    this.inputTarget.click()
  }

  selected() {
    if (this.ignoreChange) return
    const incoming = Array.from(this.inputTarget.files)
    if (incoming.length === 0) return

    const next = this.multipleValue ? this.files.concat(incoming) : incoming.slice(0, this.maxValue)
    const error = this.validationError(next)
    if (error) {
      this.inputTarget.setCustomValidity(error)
      this.setStatus(error, true)
      this.syncInput()
      return
    }

    this.files = next
    this.inputTarget.setCustomValidity("")
    this.syncInput()
    this.render()
  }

  removeSelected(event) {
    this.files.splice(Number(event.currentTarget.dataset.index), 1)
    this.inputTarget.setCustomValidity("")
    this.syncInput()
    this.render()
  }

  removePending(event) {
    event.currentTarget.closest("[data-pending-photo]").remove()
    this.existingValue = Math.max(0, this.existingValue - 1)
    this.render()
    this.setStatus("Quitamos la foto elegida. Guarda los cambios para continuar.")
  }

  started(event) { this.setStatus(`Subiendo ${event.detail.file.name}…`) }
  progress(event) { this.setStatus(`Subiendo ${event.detail.file.name}… ${Math.round(event.detail.progress)}%`) }
  finished() { this.setStatus("Fotos subidas. Guardando los detalles de la boda…") }
  failed(event) {
    event.preventDefault()
    this.setStatus("La carga no terminó. Vuelve a guardar.", true)
  }

  validationError(files) {
    if (files.some(file => !["image/jpeg", "image/png", "image/webp"].includes(file.type))) return "Elige fotos JPEG, PNG o WebP."
    if (files.some(file => file.size > 10 * 1024 * 1024)) return "Cada foto debe pesar 10 MB o menos."
    if (files.length + this.existingValue > this.maxValue) return `Esta colección puede tener hasta ${this.maxValue} fotos.`
    return ""
  }

  syncInput() {
    const transfer = new DataTransfer()
    this.files.forEach(file => transfer.items.add(file))
    this.ignoreChange = true
    this.inputTarget.files = transfer.files
    requestAnimationFrame(() => { this.ignoreChange = false })
  }

  render() {
    this.urls.forEach(url => URL.revokeObjectURL(url))
    this.urls = []
    this.previewsTarget.replaceChildren()
    this.files.forEach((file, index) => {
      const tile = document.createElement("div")
      tile.className = "photo-selection-tile"
      const image = document.createElement("img")
      const url = URL.createObjectURL(file)
      this.urls.push(url)
      image.src = url
      image.alt = `Seleccionada: ${file.name}`
      const remove = document.createElement("button")
      remove.type = "button"
      remove.className = "text-button"
      remove.textContent = "Quitar"
      remove.dataset.index = index
      remove.setAttribute("aria-label", `Quitar ${file.name}`)
      remove.dataset.action = "photo-picker#removeSelected"
      tile.append(image, remove)
      this.previewsTarget.append(tile)
    })

    if (this.files.length === 0) {
      this.setStatus("")
      return
    }

    const count = this.files.length
    const noun = count === 1 ? "foto lista" : "fotos listas"
    if (this.multipleValue) {
      const room = Math.max(this.maxValue - this.existingValue - count, 0)
      this.setStatus(`${count} ${noun}. Puedes agregar más (${room} disponibles) o guardar.`)
    } else {
      this.setStatus("Foto lista. Guarda para verla en la página.")
    }
  }

  setStatus(message, error = false) {
    this.statusTarget.textContent = message
    this.statusTarget.classList.toggle("upload-error", error)
    this.statusTarget.setAttribute("role", error ? "alert" : "status")
  }
}
