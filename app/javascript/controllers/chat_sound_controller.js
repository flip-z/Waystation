import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    currentUserId: Number,
    url: String,
  }

  connect() {
    this.audio = new Audio(this.urlValue)
    this.audio.volume = 0.5
    this.mutationObserver = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        mutation.addedNodes.forEach((node) => {
          if (!(node instanceof HTMLElement)) return
          if (!node.matches(".chat-message")) return
          this.maybePlay(node)
        })
      }
    })
    this.mutationObserver.observe(this.element, { childList: true })
  }

  disconnect() {
    if (this.mutationObserver) this.mutationObserver.disconnect()
  }

  maybePlay(node) {
    const userId = parseInt(node.dataset.messageUserId, 10)
    if (userId === this.currentUserIdValue) return

    this.playSound()
  }

  playSound() {
    if (!this.audio) return
    this.audio.currentTime = 0
    this.audio.play().catch(() => {})
  }
}
