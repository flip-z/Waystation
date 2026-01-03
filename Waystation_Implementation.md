# Waystation Implementation Plan

## Phase 0: Foundations
- Initialize Rails app, Postgres, and basic environments (development, test, production).
- Set up CI with lint/test pipeline and a minimal deployment test flow.
- Establish file storage abstraction with a local disk adapter and a cloud-ready interface (DigitalOcean Spaces later).
- Configure basic error logging and nightly backup scripts (DB + weekly file archive).
### Checkpoint
- Run locally and review core project structure before proceeding.

## Phase 1: Core Access and Site Shell
- Implement invite-only access with admin-generated, expiring, single-use links.
- Add magic-link authentication and session management.
- Define roles (Site Admin, Member) and authorization scaffolding.
- Build the global UI shell and theme system:
  - Dark purple/silver palette, pixel icon set, squared corners.
  - Early-internet layout patterns with no hover effects or transitions.
  - Base typography and component styles for blog/chat/file share.
### Checkpoint
- Verify login flow, invite handling, and UI shell before moving to content features.

## Phase 2: Blog (Markdown + Git History)
- Create blog models and admin UI for creating/editing posts.
- Store posts in a Git-backed repository or a Git-tracked content directory.
- Expose post history with date selection (read-only) and display older versions.
- Add tags, drafts, scheduled publishing, and basic view counts.
### Checkpoint
- Review post authoring flow and version history behavior before chat work.

## Phase 3: Chat (Text + Slash Commands)
- Implement single-channel real-time text chat with permanent retention.
- Add @mentions and reactions.
- Build `/campfire`:
  - Create voice room tied to the main channel thread.
  - Add profile setting for push-to-talk vs open mic.
  - Validate browser support for Chrome/Firefox/Safari.
  - Integrate LiveKit (SFU): Rails issues tokens, client connects via LiveKit SDK, and a separate LiveKit server handles media routing.
  - Document LiveKit setup (server URL, API key/secret) and local dev flow.
- Build `/beacon`:
  - Post status message to chat, display by username.
  - Default expiry 24 hours; new status overwrites existing.
### Checkpoint
- Validate chat stability and voice behavior with a small test group before file sharing.

## Phase 4: File Share + Scanning
- Build folder-based file share with RBAC (Global Read, Global Upload, Admin).
- Enforce 2 MB file size limit and configurable file type allowlist.
- Integrate malware scanning (prefer easy library, ClamAV if viable).
- Quarantine flagged files and notify Admin.
### Checkpoint
- Test upload flow, scanning, and RBAC before deployment work.

## Phase 5: Deployment and Ops
- Self-hosted local deployment for testing.
- Production deployment to DigitalOcean with IaC where feasible.
- Add deployment smoke tests and rollback procedure.
### Checkpoint
- Run full local smoke test and deployment rehearsal before public access.

## Deliverables by Phase
- Phase 0: Repo scaffold, CI, storage abstraction, backups, logging.
- Phase 1: Auth + invite system, role enforcement, themed UI shell.
- Phase 2: Blog authoring, Git history browsing, view counts.
- Phase 3: Real-time chat, slash commands, voice integration.
- Phase 4: File share, scanning pipeline, quarantine workflow.
- Phase 5: DigitalOcean deploy, deployment tests, ops docs.
