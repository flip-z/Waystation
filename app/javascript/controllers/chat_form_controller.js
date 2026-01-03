import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.element.addEventListener("turbo:submit-end", (event) => {
      if (!event.detail.success) return
      this.clearInput()
    })
  }

  keydown(event) {
    if (event.key !== "Enter") return
    if (event.shiftKey) return
    event.preventDefault()
    this.element.requestSubmit()
  }

  clearInput() {
    if (!this.hasInputTarget) return
    this.inputTarget.value = ""
    this.inputTarget.dispatchEvent(new Event("input"))
    const baseHeight = this.inputTarget.dataset.autogrowBaseHeight
    if (baseHeight) {
      this.inputTarget.style.height = `${baseHeight}px`
    } else {
      const minHeight = getComputedStyle(this.inputTarget).minHeight || "44px"
      this.inputTarget.style.minHeight = minHeight
      this.inputTarget.style.height = minHeight
    }
  }
}
