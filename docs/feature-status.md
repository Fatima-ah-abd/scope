# Feature Status

This is the working functionality tracker for the prototype.

Update it as features move from mocked to working.

## Implemented

- scope-first home with hierarchical scope cards
- customizable home title with quiet inline name editing
- scope detail view with receipts and lightweight controls
- per-scope visual identity on home cards and scope detail with generated palette, motif, and layout treatment
- optional provider-backed scope theme generation layered on top of stable defaults when OpenAI, Claude, or Gemini environment keys are configured
- sticky bottom capture dock
- one-tap audio entry from home and scope detail
- unified capture composer for text plus image/video attachments
- `Auto-scope` handoff in capture
- content-based auto-scope routing on save for text capture
- confidence-driven auto-scope outcomes:
  - high confidence applies silently
  - medium confidence applies automatically with a post-save heads-up
  - low confidence requires manual scope assignment before save
- one-tap fix path for medium-confidence auto-scope reassignment
- confidence-driven `waiting on` outcomes:
  - high confidence resolves silently
  - medium confidence resolves with an undo heads-up
  - low confidence stays unresolved and opens manual review on demand
- settings toggle for optional scope-card timestamps
- excluded memories are hidden from receipt surfaces
- redundant scope recency and memory active-state labels are hidden from primary detail surfaces

## Placeholder / Mocked

- real microphone recording
- real image picker
- `video` capture remains prototype-only and is now deferred from `v1`
- in-app provider settings and durable multi-provider configuration
- persistence beyond in-memory app state
- retrieval engine beyond seeded/mock behavior

## Current UX Rules Reflected In Build

- speed and minimalism by default
- scopes over chats
- useful outcomes over internal system state
- terse copy by default
- icon-first when the meaning is obvious in context
- auto behavior first, manual override one layer deeper

## Designed But Not Yet Implemented

- future configurability of confidence thresholds and automation behaviors

## Next Likely Steps

- remove or hide `video` from the `v1` capture path
- begin replacing in-memory storage with SwiftData and filesystem-backed assets
- connect image controls to a real device picker
- connect audio capture to real recording state
- improve auto-scope confidence with richer matching signals
