# Waystation Spec File

## Mission Statement
Waystation is a private, invite-only web app for a small trusted community centered around my personal projects. It hosts my blog/resume, a lightweight single-channel chat with voice threads, and a simple file share with content scanning. Initial scope is single-tenant (one owner/admin), not a multi-community platform.

## Audience and Scale
- Target users: 10–50 trusted members in the first year.
- Real-time chat scale: no more than 10 concurrent users.
- Platforms: Desktop-first web, with functional mobile web; no native apps.
- Accessibility: Keyboard-friendly navigation and basic ARIA labeling.

## Aesthetics
Include:
- Simple, early internet aesthetic (e.g., table-like layouts, bold borders, minimal effects).
- Pixel icons and persistent dropdowns.
- “Waystation” theme: a cross between a space port and a narrative plot point in an epic (The Odyssey, Journey to the West, Divine Comedy).
- Dark purple and silver as primary theme.

Avoid:
- Hover effects.
- Smooth transitions or animations.
- Curves (use squared corners).

## Architecture
- Framework: Ruby on Rails.
- Database: Postgres.
- Storage: Local disk for testing; abstraction to move to cloud storage later (likely DigitalOcean Spaces).
- Hosting: Self-hosted locally for testing, then DigitalOcean.
- Infrastructure as code where feasible.
- Deployment tests are welcome.
- Backups: Nightly database dumps; weekly file archive.
- Logging: Rails logs + basic error reporting.

---

# Phase One: Blog
## Requirements
- Content format: Markdown only.
- Features: Create, edit, delete posts; drafts; scheduled publish; tags.
- Versioning: Use GitHub history for posts; readers can select older versions by date. Highlighted diffs are a later enhancement.
- Viewer tracking: Basic view count per post (no per-user tracking in MVP).
- No comments in Phase One.

## Out of Scope
- Full-text search (later).
- Public RSS feed (later).

---

# Phase Two: Text and Voice Chat
## Requirements
- Single-channel text chat.
- Persistent history (permanent retention; Admin can purge).
- Message features: @mentions and reactions. No edits or deletion for now.
- Slash commands:
  1. `/campfire`: creates a voice room linked to the main channel with a dedicated thread.
     - Voice max: 10 participants.
     - Push-to-talk or open-mic profile settings.
     - Browser-first support: latest Chrome, Firefox, Safari.
  2. `/beacon`: sets a personal status that posts once to the channel and appears beside the user name.
     - Status expires after 24 hours or on manual clear.
     - Status message persists in chat history.
     - New status overwrites existing.

## Out of Scope
- Multi-channel support.

---

# Phase Three: File Share w/ Content Scanning
## Requirements
- Simple file repository with folders.
- Roles:
  - Global Read: browse and download files.
  - Global Upload: upload new files.
  - Admin: manage folders, delete files.
- File size limit: 2 MB per file.
- Allowed types: common docs, images, audio, and archives (configurable).
- Scanning: Prefer an easily implemented malware scanning library (ClamAV if viable). If flagged, file is quarantined and Admin is notified.
- Retention: deleted files are hard-deleted (no trash) in MVP.

## Out of Scope
- Per-folder permissions.
- File versioning.
- Quotas.
