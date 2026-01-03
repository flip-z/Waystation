import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const computed = getComputedStyle(this.element)
    const minHeight = parseFloat(computed.minHeight) || 0
    const lineHeight = parseFloat(computed.lineHeight) || 18
    const baseHeight = Math.max(minHeight, this.element.offsetHeight || lineHeight)
    this.element.dataset.autogrowBaseHeight = baseHeight
    if (!this.element.value.length) {
      this.element.style.height = `${baseHeight}px`
    }
    this.resize()
  }

  resize() {
    const maxRows = 5
    const lineHeight = parseFloat(getComputedStyle(this.element).lineHeight) || 18
    const maxHeight = lineHeight * maxRows
    const baseHeight = parseFloat(this.element.dataset.autogrowBaseHeight) || lineHeight

    this.element.style.height = "auto"
    const desired = this.element.value.length ? this.element.scrollHeight : baseHeight
    const next = Math.min(Math.max(desired, baseHeight), maxHeight)
    this.element.style.height = `${next}px`
  }
}
