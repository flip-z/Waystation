import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static values = {
    roomId: Number,
    peerId: String,
    micMode: String,
  }
  static targets = ["audioButton", "peerList", "debug", "toneButton"]

  connect() {
    this.peers = new Map()
    this.localStream = null
    this.audioContext = null
    this.meters = new Map()
    this.audioUnlocked = false
    this.debugMessages = []
    this.consumer = createConsumer()
    this.logDebug("Campfire controller connected.")
    if (!navigator.mediaDevices?.getUserMedia) {
      this.showStatus("Audio unavailable in this browser.")
      this.logDebug("getUserMedia unavailable.")
      return
    }
    this.setupLocalAudio()
      .then(() => this.subscribe())
      .catch((error) => {
        this.showStatus(`Audio error: ${error.message}`)
        this.logDebug(`getUserMedia error: ${error.message}`)
      })
  }

  disconnect() {
    if (this.subscription) this.subscription.unsubscribe()
    this.peers.forEach((peer) => peer.connection.close())
    this.peers.clear()
    if (this.audioContext) this.audioContext.close()
  }

  async setupLocalAudio() {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    this.localStream = stream
    this.logDebug("Microphone stream ready.")
    const audioTrack = stream.getAudioTracks()[0]
    if (audioTrack) {
      this.logDebug(`Mic track enabled: ${audioTrack.enabled}`)
      audioTrack.addEventListener("mute", () => this.logDebug("Mic track muted."))
      audioTrack.addEventListener("unmute", () => this.logDebug("Mic track unmuted."))
      audioTrack.addEventListener("ended", () => this.logDebug("Mic track ended."))
    }
    if (this.micModeValue === "push_to_talk") {
      audioTrack.enabled = false
      this.showStatus("Push-to-talk enabled. Hold the button to speak.")
    } else {
      audioTrack.enabled = true
      this.showStatus("Open mic enabled.")
    }
    if (this.peerIdValue) {
      this.ensurePeerIndicator(this.peerIdValue, "You", true)
      this.setupAudioMeter(stream, this.peerIdValue)
    }
  }

  subscribe() {
    const peerId = this.peerIdValue || crypto.randomUUID()
    this.peerIdValue = peerId
    const roomId = this.roomIdValue
    if (!roomId) {
      this.showStatus("Missing room id for voice.")
      this.logDebug("Missing room id; skipping subscribe.")
      return
    }
    this.subscriptionConnected = false
    this.subscription = this.consumer.subscriptions.create(
      { channel: "CampfireChannel", room_id: roomId, peer_id: peerId },
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
        received: (data) => this.handleSignal(data),
      }
    )
    this.showStatus("Connecting voice channel...")
    this.logDebug(`Peer id: ${peerId}`)
    this.logDebug(`Cable state: ${this.consumer.connection.getState()}`)
    setTimeout(() => {
      if (!this.subscriptionConnected) {
        this.logDebug("No channel confirmation yet.")
      }
    }, 1200)
    if (this.localStream) {
      this.ensurePeerIndicator(peerId, "You", true)
      this.setupAudioMeter(this.localStream, peerId)
    }
  }

  handleSignal(data) {
    if (data.type === "participants") {
      this.logDebug(`Participants: ${data.peers.length}`)
      data.peers.filter((peer) => peer !== this.peerIdValue).forEach((peer) => {
        this.ensurePeer(peer, true)
      })
      return
    }

    if (data.type === "leave" && data.peer_id) {
      this.logDebug(`Peer left: ${data.peer_id}`)
      this.removePeer(data.peer_id)
      return
    }

    if (data.type === "signal") {
      if (data.target_id && data.target_id !== this.peerIdValue) return
      if (!data.sender_id) return
      this.logDebug(`Signal ${data.signal?.type} from ${data.sender_id}`)
      this.handlePeerSignal(data.sender_id, data.signal)
    }
  }

  ensurePeer(peerId, initiator = false) {
    if (this.peers.has(peerId)) return
    const connection = new RTCPeerConnection({
      iceServers: [{ urls: "stun:stun.l.google.com:19302" }],
    })

    this.localStream.getTracks().forEach((track) => {
      connection.addTrack(track, this.localStream)
    })

    connection.onicecandidate = (event) => {
      if (!event.candidate) return
      this.sendSignal(peerId, { type: "ice", candidate: event.candidate })
    }

    connection.ontrack = (event) => {
      this.attachRemoteAudio(peerId, event.streams[0])
    }

    connection.oniceconnectionstatechange = () => {
      this.showStatus(
        `Peer ${peerId.slice(0, 4)} ICE: ${connection.iceConnectionState}`
      )
      this.logDebug(`ICE ${peerId.slice(0, 4)}: ${connection.iceConnectionState}`)
    }

    connection.onconnectionstatechange = () => {
      this.showStatus(
        `Peer ${peerId.slice(0, 4)} state: ${connection.connectionState}`
      )
      this.logDebug(`State ${peerId.slice(0, 4)}: ${connection.connectionState}`)
      if (connection.connectionState === "connected") {
        this.logStats(peerId)
      }
    }

    connection.onicecandidateerror = () => {
      this.showStatus(`Peer ${peerId.slice(0, 4)} ICE error`)
      this.logDebug(`ICE error ${peerId.slice(0, 4)}`)
    }

    this.peers.set(peerId, { connection, stream: null })
    this.ensurePeerIndicator(peerId, `Peer ${peerId.slice(0, 4)}`, false)

    if (initiator) {
      connection
        .createOffer()
        .then((offer) => connection.setLocalDescription(offer))
        .then(() => {
          this.sendSignal(peerId, { type: "offer", sdp: connection.localDescription })
        })
        .catch((error) => {
          this.showStatus(`Offer error: ${error.message}`)
        })
    }
  }

  handlePeerSignal(peerId, signal) {
    this.ensurePeer(peerId, false)
    const { connection } = this.peers.get(peerId)

    if (signal.type === "offer") {
      connection
        .setRemoteDescription(new RTCSessionDescription(signal.sdp))
        .then(() => connection.createAnswer())
        .then((answer) => connection.setLocalDescription(answer))
        .then(() => {
          this.sendSignal(peerId, { type: "answer", sdp: connection.localDescription })
        })
        .catch((error) => {
          this.showStatus(`Answer error: ${error.message}`)
        })
    } else if (signal.type === "answer") {
      connection.setRemoteDescription(new RTCSessionDescription(signal.sdp))
    } else if (signal.type === "ice") {
      connection.addIceCandidate(new RTCIceCandidate(signal.candidate))
    }
  }

  attachRemoteAudio(peerId, stream) {
    if (this.peers.get(peerId)?.stream) return
    const audio = document.createElement("audio")
    audio.autoplay = true
    audio.playsInline = true
    audio.muted = false
    audio.volume = 1
    audio.srcObject = stream
    audio.dataset.peer = peerId
    audio.addEventListener("play", () => this.logDebug(`Audio playing: ${peerId.slice(0, 4)}`))
    this.element.querySelector(".campfire-audio").appendChild(audio)
    this.peers.get(peerId).stream = stream
    this.setupAudioMeter(stream, peerId)
    this.playAudio(audio)
    this.logDebug(`Remote audio attached: ${peerId.slice(0, 4)}`)
  }

  removePeer(peerId) {
    const peer = this.peers.get(peerId)
    if (!peer) return
    peer.connection.close()
    this.peers.delete(peerId)
    const audio = this.element.querySelector(`audio[data-peer="${peerId}"]`)
    if (audio) audio.remove()
    const indicator = this.element.querySelector(`[data-peer-indicator="${peerId}"]`)
    if (indicator) indicator.remove()
  }

  sendSignal(targetId, signal) {
    if (!this.subscription) return
    this.subscription.perform("signal", { target_id: targetId, signal })
  }

  pushToTalkStart() {
    if (this.micModeValue !== "push_to_talk") return
    const track = this.localStream?.getAudioTracks()[0]
    if (track) {
      track.enabled = true
      this.logDebug("Push-to-talk: mic enabled.")
    }
  }

  pushToTalkEnd() {
    if (this.micModeValue !== "push_to_talk") return
    const track = this.localStream?.getAudioTracks()[0]
    if (track) {
      track.enabled = false
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

  playTestTone() {
    if (!window.AudioContext && !window.webkitAudioContext) {
      this.showStatus("Audio unavailable in this browser.")
      return
    }
    if (!this.audioContext) {
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
    }
    if (this.audioContext.state === "suspended") {
      this.audioContext.resume()
    }
    const oscillator = this.audioContext.createOscillator()
    const gain = this.audioContext.createGain()
    oscillator.frequency.value = 440
    gain.gain.value = 0.2
    oscillator.connect(gain).connect(this.audioContext.destination)
    oscillator.start()
    oscillator.stop(this.audioContext.currentTime + 0.25)
    this.logDebug("Test tone played.")
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

  ensurePeerIndicator(peerId, label, isLocal) {
    if (!this.hasPeerListTarget) return
    if (this.element.querySelector(`[data-peer-indicator="${peerId}"]`)) return
    const indicator = document.createElement("div")
    indicator.className = `peer-indicator ${isLocal ? "peer-indicator-local" : "peer-indicator-remote"}`
    indicator.dataset.peerIndicator = peerId
    indicator.textContent = label
    this.peerListTarget.appendChild(indicator)
  }

  setupAudioMeter(stream, peerId) {
    if (!window.AudioContext && !window.webkitAudioContext) return
    if (!this.audioContext) {
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
    }

    const source = this.audioContext.createMediaStreamSource(stream)
    const analyser = this.audioContext.createAnalyser()
    analyser.fftSize = 512
    source.connect(analyser)
    const dataArray = new Uint8Array(analyser.frequencyBinCount)
    this.meters.set(peerId, { analyser, dataArray })

    const tick = () => {
      analyser.getByteFrequencyData(dataArray)
      const average = dataArray.reduce((sum, value) => sum + value, 0) / dataArray.length
      const indicator = this.element.querySelector(`[data-peer-indicator="${peerId}"]`)
      if (indicator) {
        indicator.classList.toggle("speaking", average > 28)
      }
      requestAnimationFrame(tick)
    }
    requestAnimationFrame(tick)
  }

  showStatus(message) {
    const status = this.element.querySelector("[data-campfire-status]")
    if (status) status.textContent = message
  }

  logDebug(message) {
    if (!this.hasDebugTarget) return
    const timestamp = new Date().toLocaleTimeString()
    this.debugMessages.unshift(`[${timestamp}] ${message}`)
    this.debugMessages = this.debugMessages.slice(0, 6)
    this.debugTarget.textContent = this.debugMessages.join("\n")
  }

  logStats(peerId) {
    const peer = this.peers.get(peerId)
    if (!peer) return
    peer.connection.getStats(null).then((stats) => {
      let inbound = null
      let outbound = null
      stats.forEach((report) => {
        if (report.type === "inbound-rtp" && report.kind === "audio") {
          inbound = report
        }
        if (report.type === "outbound-rtp" && report.kind === "audio") {
          outbound = report
        }
      })
      if (inbound) {
        this.logDebug(
          `Inbound audio bytes: ${inbound.bytesReceived || 0}`
        )
      }
      if (outbound) {
        this.logDebug(
          `Outbound audio bytes: ${outbound.bytesSent || 0}`
        )
      }
    })
  }
}
