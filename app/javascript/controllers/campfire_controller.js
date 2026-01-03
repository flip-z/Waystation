import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"
import { Room, RoomEvent, Track } from "livekit-client"

export default class extends Controller {
  static values = {
    roomId: Number,
    peerId: String,
    micMode: String,
    voiceTokenUrl: String,
  }
  static targets = ["audioButton", "micModeSelect", "peerList", "presenceCount", "pushToTalkButton", "voiceModeHint", "voiceToggle"]

  connect() {
    this.audioContext = null
    this.audioUnlocked = false
    this.debugMessages = []
    this.audioElements = new Map()
    this.presenceByPeerId = new Map()
    this.presencePeers = new Map()
    this.activeSpeakers = new Set()
    this.voiceParticipants = new Set()
    this.room = null
    this.voiceConnected = false
    this.pushToTalkKeyDown = false
    this.consumer = createConsumer()
    this.logDebug("Campfire controller connected.")

    if (!this.roomIdValue) {
      this.showStatus("Missing room id for voice.")
      this.logDebug("Missing room id; skipping voice setup.")
      return
    }

    this.subscribePresence()
    this.bindPushToTalkHotkey()
    this.updateVoiceControls()
    this.connectLivekit().catch((error) => {
      this.showStatus("Voice connection failed.")
      this.logDebug(`LiveKit error: ${error.message || error}`)
    })
  }

  disconnect() {
    if (this.subscription) this.subscription.unsubscribe()
    this.unbindPushToTalkHotkey()
    this.disconnectLivekit()
    this.audioElements.forEach((audio) => audio.remove())
    this.audioElements.clear()
    if (this.audioContext) this.audioContext.close()
  }

  subscribePresence() {
    const peerId = this.peerIdValue || crypto.randomUUID()
    this.peerIdValue = peerId
    this.subscriptionConnected = false
    this.subscription = this.consumer.subscriptions.create(
      { channel: "CampfireChannel", room_id: this.roomIdValue, peer_id: peerId },
      {
        connected: () => {
          this.subscriptionConnected = true
          this.logDebug("Connected to CampfireChannel.")
        },
        disconnected: () => {
          this.logDebug("Disconnected from CampfireChannel.")
        },
        rejected: () => {
          this.logDebug("CampfireChannel rejected subscription.")
        },
        received: (data) => {
          if (data.type === "participants") {
            this.resetPresence(data.participants || [])
          }
          if (data.type === "join") {
            this.addPresencePeer(data.participant)
          }
          if (data.type === "leave") {
            this.removePresencePeer(data.participant)
          }
        },
      }
    )
    this.logDebug(`Presence peer id: ${peerId}`)
  }

  async connectLivekit() {
    if (this.voiceConnected) return
    if (!this.hasVoiceTokenUrlValue) {
      this.showStatus("LiveKit token endpoint missing.")
      this.logDebug("Missing campfire_voice_token_url.")
      return
    }

    this.showStatus("Connecting voice server...")
    const { token, url } = await this.fetchToken()
    const room = new Room()
    this.room = room

    room.on(RoomEvent.ConnectionStateChanged, (state) => {
      this.showStatus(`Voice state: ${state}`)
      this.logDebug(`LiveKit state: ${state}`)
    })

    room.on(RoomEvent.ParticipantConnected, (participant) => {
      this.addVoiceParticipant(participant.identity)
      this.logDebug(`Participant joined: ${participant.identity}`)
    })

    room.on(RoomEvent.ParticipantDisconnected, (participant) => {
      this.removeVoiceParticipant(participant.identity)
      this.removePeer(participant.identity)
      this.logDebug(`Participant left: ${participant.identity}`)
    })

    room.on(RoomEvent.TrackSubscribed, (track, publication, participant) => {
      if (track.kind !== Track.Kind.Audio) return
      if (participant.isLocal) return
      this.attachRemoteAudio(participant.identity, track)
    })

    room.on(RoomEvent.TrackUnsubscribed, (track, publication, participant) => {
      if (track.kind !== Track.Kind.Audio) return
      this.removeRemoteAudio(participant.identity)
    })

    room.on(RoomEvent.ActiveSpeakersChanged, (speakers) => {
      this.activeSpeakers = new Set(speakers.map((participant) => participant.identity))
      this.updateSpeakingIndicators()
    })

    await room.connect(url, token, { autoSubscribe: true })
    this.voiceConnected = true
    this.syncVoiceParticipants()
    this.updateVoiceControls()
    this.renderPresence()

    if (this.micModeValue === "push_to_talk") {
      await room.localParticipant.setMicrophoneEnabled(false)
      this.showStatus("Push-to-talk enabled. Hold the button to speak.")
    } else {
      await room.localParticipant.setMicrophoneEnabled(true)
      this.showStatus("Open mic enabled.")
    }

    this.logDebug("Connected to LiveKit.")
  }

  async fetchToken() {
    const tokenUrl = this.voiceTokenUrlValue
    const csrf = document.querySelector("meta[name=csrf-token]")?.content
    const response = await fetch(tokenUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrf || "",
      },
      body: JSON.stringify({}),
    })
    if (!response.ok) {
      const contentType = response.headers.get("content-type") || ""
      const payload = await response.text()
      let message = "Unable to fetch LiveKit token."
      if (contentType.includes("application/json")) {
        try {
          const data = JSON.parse(payload)
          message = data.error || message
        } catch {
          message = message
        }
      } else if (contentType.includes("text/html") || payload.trim().startsWith("<!DOCTYPE")) {
        message = "LiveKit token endpoint returned HTML. Check server logs."
      } else if (payload) {
        message = payload
      }
      message = this.compactError(message)
      this.logDebug(`LiveKit token error (${response.status}): ${message}`)
      throw new Error(message)
    }
    return response.json()
  }

  attachRemoteAudio(identity, track) {
    if (this.audioElements.has(identity)) return
    const audio = track.attach()
    audio.autoplay = true
    audio.playsInline = true
    audio.dataset.peer = identity
    this.element.querySelector(".campfire-audio").appendChild(audio)
    this.audioElements.set(identity, audio)
    this.playAudio(audio)
    this.logDebug(`Remote audio attached: ${identity}`)
  }

  removeRemoteAudio(identity) {
    const audio = this.audioElements.get(identity)
    if (audio) audio.remove()
    this.audioElements.delete(identity)
  }

  removePeer(identity) {
    this.removeRemoteAudio(identity)
  }

  toggleVoice() {
    if (this.voiceConnected) {
      this.leaveVoice()
    } else {
      this.joinVoice()
    }
  }

  async joinVoice() {
    await this.connectLivekit()
  }

  leaveVoice() {
    this.disconnectLivekit()
    this.showStatus("Voice disconnected.")
    this.logDebug("Disconnected from LiveKit.")
  }

  disconnectLivekit() {
    if (!this.room) return
    this.room.disconnect()
    this.room = null
    this.voiceConnected = false
    this.activeSpeakers = new Set()
    this.voiceParticipants = new Set()
    this.audioElements.forEach((audio) => audio.remove())
    this.audioElements.clear()
    this.hideAudioButton()
    this.updateSpeakingIndicators()
    this.updateVoicePresenceIndicators()
    this.updateVoiceControls()
  }

  pushToTalkStart() {
    if (this.micModeValue !== "push_to_talk") return
    if (this.room) {
      this.room.localParticipant.setMicrophoneEnabled(true)
      this.logDebug("Push-to-talk: mic enabled.")
    }
  }

  pushToTalkEnd() {
    if (this.micModeValue !== "push_to_talk") return
    if (this.room) {
      this.room.localParticipant.setMicrophoneEnabled(false)
      this.logDebug("Push-to-talk: mic disabled.")
    }
  }

  enableAudio() {
    if (this.audioContext && this.audioContext.state === "suspended") {
      this.audioContext.resume()
    }
    this.audioUnlocked = true
    this.hideAudioButton()
    this.showStatus("Audio enabled.")
    this.logDebug("Audio enabled by user gesture.")
    this.element.querySelectorAll(".campfire-audio audio").forEach((audio) => {
      audio.play().catch(() => {
        this.showAudioButton()
      })
    })
  }

  async changeMicMode(event) {
    const selected = event?.target?.value
    if (!selected || selected === this.micModeValue) return
    this.micModeValue = selected
    this.updateVoiceControls()

    if (this.room && this.voiceConnected) {
      if (this.micModeValue === "push_to_talk") {
        await this.room.localParticipant.setMicrophoneEnabled(false)
      } else {
        await this.room.localParticipant.setMicrophoneEnabled(true)
      }
    }

    await this.persistMicMode()
  }

  playAudio(audio) {
    audio
      .play()
      .then(() => {
        this.audioUnlocked = true
        this.hideAudioButton()
        this.showStatus("Audio enabled.")
        this.logDebug("Audio playback started.")
      })
      .catch(() => {
        this.showAudioButton()
        this.showStatus("Audio blocked. Click Enable Audio.")
        this.logDebug("Audio playback blocked.")
      })
  }

  showAudioButton() {
    if (!this.hasAudioButtonTarget) return
    this.audioButtonTarget.hidden = false
  }

  hideAudioButton() {
    if (!this.hasAudioButtonTarget) return
    this.audioButtonTarget.hidden = true
  }

  resetPresence(participants) {
    this.presenceByPeerId.clear()
    this.presencePeers.clear()
    participants.forEach((participant) => this.trackPresence(participant))
    this.renderPresence()
  }

  addPresencePeer(participant) {
    if (!participant) return
    this.trackPresence(participant)
    this.renderPresence()
  }

  removePresencePeer(participant) {
    if (!participant) return
    const peerId = participant.peer_id
    const userId = participant.user_id ? String(participant.user_id) : this.presenceByPeerId.get(peerId)?.userId
    if (!peerId || !userId) return
    this.presenceByPeerId.delete(peerId)
    const entry = this.presencePeers.get(userId)
    if (!entry) return
    entry.count -= 1
    if (entry.count <= 0) {
      this.presencePeers.delete(userId)
    } else {
      this.presencePeers.set(userId, entry)
    }
    this.renderPresence()
  }

  trackPresence(participant) {
    const peerId = participant.peer_id
    const userId = participant.user_id ? String(participant.user_id) : null
    if (!peerId || !userId) return
    this.presenceByPeerId.set(peerId, { userId: userId })
    const entry = this.presencePeers.get(userId) || { count: 0, handle: participant.handle }
    entry.count += 1
    if (!entry.handle && participant.handle) entry.handle = participant.handle
    this.presencePeers.set(userId, entry)
  }

  renderPresence() {
    if (!this.hasPeerListTarget) return
    this.peerListTarget.innerHTML = ""
    const entries = Array.from(this.presencePeers.entries()).map(([userId, data]) => ({
      userId: userId,
      label: this.displayNameForPresence(userId, data.handle),
    }))
    entries.sort((a, b) => a.label.localeCompare(b.label))
    entries.forEach((entry) => {
      const item = document.createElement("li")
      const indicator = document.createElement("span")
      indicator.className = "talk-indicator"
      indicator.dataset.peerIndicator = entry.userId
      indicator.textContent = "o"
      const voiceStatus = document.createElement("span")
      voiceStatus.className = "voice-indicator"
      voiceStatus.dataset.voiceIndicator = entry.userId
      voiceStatus.setAttribute("aria-hidden", "true")
      voiceStatus.setAttribute("title", "Not in voice")
      const name = document.createElement("span")
      name.classList.add(`chat-user-${entry.userId}`)
      name.dataset.peerName = "true"
      name.textContent = entry.label
      item.append(indicator, voiceStatus, name)
      this.peerListTarget.appendChild(item)
    })
    this.updatePresenceCount()
    this.updateSpeakingIndicators()
    this.updateVoicePresenceIndicators()
  }

  displayNameForPresence(userId, handle) {
    if (this.room?.localParticipant?.identity === userId) return "You"
    if (handle) return handle
    return `User ${userId}`
  }

  updateSpeakingIndicators() {
    this.element.querySelectorAll("[data-peer-indicator]").forEach((indicator) => {
      const id = indicator.dataset.peerIndicator
      indicator.classList.toggle("speaking", this.activeSpeakers.has(id))
    })
  }

  updateVoicePresenceIndicators() {
    this.element.querySelectorAll("[data-voice-indicator]").forEach((indicator) => {
      const id = indicator.dataset.voiceIndicator
      indicator.hidden = !this.voiceConnected || this.voiceParticipants.has(id)
    })
  }

  updatePresenceCount() {
    if (!this.hasPresenceCountTarget) return
    this.presenceCountTarget.textContent = `(${this.presencePeers.size})`
  }

  updateVoiceControls() {
    if (this.hasMicModeSelectTarget) {
      this.micModeSelectTarget.value = this.micModeValue
    }
    if (this.hasVoiceModeHintTarget) {
      this.voiceModeHintTarget.textContent = this.micModeValue === "push_to_talk" ? "Hotkey ` (works while typing)" : ""
    }
    if (this.hasPushToTalkButtonTarget) {
      const isPushToTalk = this.micModeValue === "push_to_talk"
      this.pushToTalkButtonTarget.hidden = !isPushToTalk
      this.pushToTalkButtonTarget.disabled = !this.voiceConnected
      this.pushToTalkButtonTarget.setAttribute("aria-disabled", String(!this.voiceConnected))
    }
    if (this.hasVoiceToggleTarget) {
      this.voiceToggleTarget.textContent = this.voiceConnected ? "Leave Voice" : "Join Voice"
      this.voiceToggleTarget.classList.toggle("button-voice-join", !this.voiceConnected)
      this.voiceToggleTarget.classList.toggle("button-voice-leave", this.voiceConnected)
    }
  }

  bindPushToTalkHotkey() {
    this.handlePushToTalkKeydown = this.handlePushToTalkKeydown.bind(this)
    this.handlePushToTalkKeyup = this.handlePushToTalkKeyup.bind(this)
    window.addEventListener("keydown", this.handlePushToTalkKeydown)
    window.addEventListener("keyup", this.handlePushToTalkKeyup)
  }

  unbindPushToTalkHotkey() {
    if (this.handlePushToTalkKeydown) {
      window.removeEventListener("keydown", this.handlePushToTalkKeydown)
      window.removeEventListener("keyup", this.handlePushToTalkKeyup)
    }
  }

  handlePushToTalkKeydown(event) {
    if (!this.shouldHandlePushToTalk(event)) return
    if (event.repeat) return
    this.pushToTalkKeyDown = true
    this.maybePreventPushToTalkKey(event)
    this.pushToTalkStart()
  }

  handlePushToTalkKeyup(event) {
    if (!this.shouldHandlePushToTalk(event)) return
    if (!this.pushToTalkKeyDown) return
    this.pushToTalkKeyDown = false
    this.maybePreventPushToTalkKey(event)
    this.pushToTalkEnd()
  }

  shouldHandlePushToTalk(event) {
    if (this.micModeValue !== "push_to_talk") return false
    if (!this.voiceConnected || !this.room) return false
    if (event.code !== "Backquote") return false
    if (event.altKey || event.ctrlKey || event.metaKey) return false
    return true
  }

  maybePreventPushToTalkKey(event) {
    const target = event.target
    const tag = target?.tagName?.toLowerCase()
    const isInput = tag === "input" || tag === "textarea" || target?.isContentEditable
    if (isInput) event.preventDefault()
  }

  showStatus(message) {
    const status = this.element.querySelector("[data-campfire-status]")
    if (status) status.textContent = message
  }

  syncVoiceParticipants() {
    if (!this.room) return
    this.voiceParticipants = new Set()
    if (this.room.localParticipant?.identity) {
      this.voiceParticipants.add(this.room.localParticipant.identity)
    }
    this.room.remoteParticipants.forEach((participant) => {
      this.voiceParticipants.add(participant.identity)
    })
    this.updateVoicePresenceIndicators()
  }

  addVoiceParticipant(identity) {
    if (!identity) return
    this.voiceParticipants.add(identity)
    this.updateVoicePresenceIndicators()
  }

  removeVoiceParticipant(identity) {
    if (!identity) return
    this.voiceParticipants.delete(identity)
    this.updateVoicePresenceIndicators()
  }

  async persistMicMode() {
    const csrf = document.querySelector("meta[name=csrf-token]")?.content
    try {
      const response = await fetch("/profile", {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": csrf || "",
        },
        body: JSON.stringify({ user: { mic_mode: this.micModeValue } }),
      })
      if (!response.ok) {
        const payload = await response.text()
        this.logDebug(`Mic mode update failed (${response.status}): ${payload}`)
      }
    } catch (error) {
      this.logDebug(`Mic mode update failed: ${error.message || error}`)
    }
  }

  logDebug(message) {
    if (!this.hasDebugTarget) return
    const timestamp = new Date().toLocaleTimeString()
    this.debugMessages.unshift(`[${timestamp}] ${this.compactError(message)}`)
    this.debugMessages = this.debugMessages.slice(0, 6)
    this.debugTarget.textContent = this.debugMessages.join("\n")
  }

  compactError(message) {
    if (!message) return "Unknown error"
    const trimmed = String(message).replace(/\s+/g, " ").trim()
    const max = 200
    if (trimmed.length <= max) return trimmed
    return `${trimmed.slice(0, max)}...`
  }
}
