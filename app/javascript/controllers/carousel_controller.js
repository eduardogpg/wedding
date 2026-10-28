import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track", "slide", "previous", "next", "dot", "counter"]

  connect() {
    this.index = 0
    this.frame = null
    this.resizeObserver = new ResizeObserver(() => this.sync())
    this.resizeObserver.observe(this.trackTarget)
    this.sync()
  }

  disconnect() {
    this.resizeObserver.disconnect()
    cancelAnimationFrame(this.frame)
  }

  previous() { this.goTo(this.index - 1) }
  next() { this.goTo(this.index + 1) }
  choose(event) { this.goTo(Number(event.currentTarget.dataset.index)) }

  keydown(event) {
    const destinations = { ArrowLeft: this.index - 1, ArrowRight: this.index + 1, Home: 0, End: this.slideTargets.length - 1 }
    if (!(event.key in destinations) || event.altKey || event.ctrlKey || event.metaKey) return
    event.preventDefault()
    this.goTo(destinations[event.key])
  }

  goTo(index) {
    const target = Math.max(0, Math.min(index, this.slideTargets.length - 1))
    const behavior = window.matchMedia("(prefers-reduced-motion: reduce)").matches ? "instant" : "smooth"
    this.trackTarget.scrollTo({ left: this.slideTargets[target].offsetLeft, behavior })
  }

  sync() {
    cancelAnimationFrame(this.frame)
    this.frame = requestAnimationFrame(() => {
      const left = this.trackTarget.scrollLeft
      this.index = this.slideTargets.reduce((nearest, slide, index) =>
        Math.abs(slide.offsetLeft - left) < Math.abs(this.slideTargets[nearest].offsetLeft - left) ? index : nearest, 0)
      if (this.hasPreviousTarget) this.previousTarget.disabled = this.index === 0
      if (this.hasNextTarget) this.nextTarget.disabled = this.index === this.slideTargets.length - 1
      this.dotTargets.forEach((dot, index) => {
        if (index === this.index) dot.setAttribute("aria-current", "true")
        else dot.removeAttribute("aria-current")
      })
      if (this.hasCounterTarget) {
        const text = `Photo ${this.index + 1} of ${this.slideTargets.length}`
        if (this.counterTarget.textContent !== text) this.counterTarget.textContent = text
      }
    })
  }
}
