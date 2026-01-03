import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["badge"]
  static values = { onChat: Boolean, currentUserId: Number }

  connect() {
    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create(
      { channel: "NotificationChannel" },
      { received: (data) => this.handleNotification(data) }
    )

    if (this.onChatValue) {
      this.clearBadge()
    }
  }

  disconnect() {
    if (this.subscription) {
      this.consumer.subscriptions.remove(this.subscription)
    }
  }

  handleNotification(data) {
    if (this.onChatValue) {
      return
    }

    if (this.currentUserIdValue && data.user_id === this.currentUserIdValue) {
      return
    }

    this.showBadge()
  }

  showBadge() {
    if (!this.hasBadgeTarget) {
      return
    }

    this.badgeTarget.hidden = false
  }

  clearBadge() {
    if (!this.hasBadgeTarget) {
      return
    }

    this.badgeTarget.hidden = true
  }
}
