import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { container: Boolean }

  connect() {
    this.mutationObserver = new MutationObserver(() => this.scrollIfNearBottom())
    this.mutationObserver.observe(this.element, { childList: true, subtree: true })
    this.scrollToBottom()
  }

  disconnect() {
    if (this.mutationObserver) this.mutationObserver.disconnect()
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }

  scrollIfNearBottom() {
    const threshold = 120
    const distance = this.element.scrollHeight - this.element.scrollTop - this.element.clientHeight
    if (distance <= threshold) {
      this.scrollToBottom()
    }
  }
}
