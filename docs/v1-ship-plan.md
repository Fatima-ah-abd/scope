# V1 Ship Plan

## Purpose

This document outlines everything still required to turn the current `Scope` prototype into a shippable `v1`.

It also records the current `v1` cut line so the repo has one durable answer for:

- what is already true in the prototype
- what is still missing for `v1`
- what we are explicitly cutting from `v1`
- what milestone comes next

Here, **shippable v1** means:

- the app can be released to external users via TestFlight
- the product loop is real, not mocked
- the app is durable enough to trust for ongoing personal use
- the remaining gaps to App Store submission are mostly metadata, copy, and final QA

This plan is intentionally narrower than the full product vision.

## Starting Point

The current prototype already proves:

- scope-first home
- scope detail
- one-tap capture entry
- unified capture composer
- confidence-based `Auto-scope`
- confidence-based `waiting on` resolution
- receipts and lightweight exclusion controls

The main missing pieces are:

- real capture plumbing
- durable storage
- real provider integration
- real retrieval and assistant behavior
- onboarding, settings, and release readiness

## V1 Assumptions

This plan assumes:

- `v1` is **iPhone-first**
- `v1` supports **BYO API keys**
- `v1` ships with **one provider integration first**
- `v1` supports **text, audio, and image capture**
- `video` capture is **deferred to `v1.1`**
- `link` capture is **deferred until after `v1`**
- the `v1` assistant surface is **in-scope ask only**
- `v1` uses **local durable storage** as the working copy
- `iCloud sync + export/import` remain a `v1.5` fast follow
- dedicated memory review remains `v2`

If any of those assumptions change, the scope of `v1` changes materially.

## Not Required For V1

These should stay out of the critical path unless priorities change:

- `video` capture and picker support
- `link` capture
- iCloud sync
- export/import
- collaboration or public sharing
- hosted billing
- multi-user accounts
- autonomous background agent systems
- deep bulk memory review workflows
- advanced provider marketplace support

## Status Snapshot

As of `2026-04-24`, the repo is here:

- strong in prototype shell and trust behaviors:
  - scope-first home and scope detail
  - one-tap capture entry
  - confidence-based `Auto-scope`
  - confidence-based `waiting on` resolution
  - lightweight receipts and exclusion controls
  - per-scope visual identity
- partial in core product completeness:
  - create and open scope flows exist
  - memory controls exist in prototype form
  - timestamps setting exists
  - rename, archive/delete, onboarding, and provider settings are still missing
- not started or still mocked on the critical `v1` path:
  - durable persistence
  - real audio recording
  - real image picking
  - derivation and retrieval based on real saved content
  - in-app BYO key setup
  - in-scope assistant sessions backed by real retrieval events
  - release gating and tests beyond compilation
- repo-level `v1` cut decisions now locked:
  - `video` moves to `v1.1`
  - `link` capture stays out of `v1`
  - `v1` assistant is in-scope only
  - the next milestone is `Durable Data Foundation`

## Definition Of Done

`v1` is done when a user can:

1. install the app and understand what it is for
2. create a scope and return to it later
3. capture text, audio, and image content for that scope
4. trust that captures persist across relaunches
5. let the app auto-scope when confidence is high
6. correct or review automation when confidence is not high
7. ask inside a scope and get a useful response grounded in the right memory
8. inspect what context was used and exclude it if needed
9. configure a BYO provider key without confusion
10. use the app without hitting dead ends, placeholder UI, or misleading signals

## Remaining Workstreams

### 1. Scope Freeze And Product Cleanup

Before deeper implementation work, lock the `v1` boundary.

#### Status Now

- **partial**
- the shell is strong, but the cut line is not fully applied in the product yet
- `video` still appears in the prototype composer
- `Archived` still appears as a dead affordance
- seeded-only background signals still appear in the prototype

#### Required

- lock the minimum supported capture set for `v1`
  - text
  - audio
  - image
- move `video` to `v1.1`
  - remove or hide `video` from the `v1` path
  - do not keep placeholder `video` affordances on primary surfaces
- defer `link` capture until after `v1`
- remove or implement any remaining dead UI affordances
  - `Archived`
  - seeded-only background signals
  - any placeholder copy that suggests functionality not yet present
- lock the exact `v1` assistant surface
  - in-scope ask only
  - no global assistant

#### Output

- no misleading buttons
- no prototype-only language on primary surfaces
- one clear `v1` scope statement the whole repo follows

### 2. Durable Data Foundation

The prototype currently relies on in-memory state. That is the biggest gap between `v0` and `v1`.

#### Status Now

- **not started**
- the app still boots from seeded in-memory state
- capture save paths still write only to in-memory records
- this is the next milestone because it is the trust gate for everything after it

#### Required

- implement the first durable store using:
  - `SwiftData` for structured records
  - filesystem storage for original assets and large derived artifacts
  - `Keychain` for provider keys
- map prototype models to the public core model
  - `Scope`
  - `ScopeCategory`
  - `SourceAsset`
  - `DerivedArtifact`
  - `MemoryItem`
  - `ScopeSession`
  - `SessionTurn`
  - `RetrievalEvent`
- make the app load from persisted state on launch
- make capture saves durable before dismissal
- ensure the app can recover cleanly from relaunch
- add basic storage organization and cleanup rules
- ensure asset paths and structured records stay in sync

#### Required UX Behavior

- nothing important is lost on relaunch
- source assets remain inspectable later
- receipts and recent memory reflect real persisted records

#### Output

- a working local database and asset store
- no prototype-only seeded state required for the app to function

### 3. Real Capture And Permissions

The app needs real ingestion, not simulated capture.

#### Status Now

- **not started**
- audio recording is currently simulated UI state
- image and `video` attachments are currently prototype toggles rather than real media flows
- only microphone usage messaging is currently wired

#### Required

- implement real audio recording
  - record
  - pause/resume if kept in the design
  - save/discard
  - microphone permission flow
- implement real image picking
  - photo library permission flow
  - asset persistence
- make the unified composer work with real attachments
- add basic failure states
  - permission denied
  - save failure
  - unsupported media or oversized media

#### Strongly Recommended

- keep capture entry one-tap where designed
- use just-in-time permissions rather than front-loading prompts
- make attachment state explicit but quiet

#### Output

- a user can create real captures that survive relaunch

### 4. Derivation And Memory Processing

Raw assets alone are not enough. `v1` needs the first useful memory-processing layer.

#### Status Now

- **not started**
- captures currently become prototype memory records directly
- `Auto-scope` and `waiting on` still rely on prototype heuristics and seeded content rather than durable derivation output

#### Required

- implement text capture promotion into `MemoryItem`s
- implement audio derivation
  - transcription
  - summary or extracted memory candidates
- implement image derivation
  - OCR where relevant
  - lightweight semantic description or extraction
- implement category suggestion and assignment for saved memories
- persist derived artifacts separately from promoted memory
- make `Auto-scope` use real derivation output where needed
- make `waiting on` resolution operate on real saved content rather than prototype assumptions

#### Quality Bar

- the app should not need full multimodal retrieval for `v1`
- it should retrieve from structured memory most of the time
- the original asset should remain available as the source of truth

#### Output

- captures become useful memory, not just stored files

### 5. BYO Provider Setup

The product promise depends on user-controlled provider access.

#### Status Now

- **not started for `v1`**
- provider-backed scope theme generation exists behind environment variables, but in-app BYO key setup and durable provider configuration do not exist yet

#### Required

- implement provider settings UI
- add BYO API key entry and secure storage
- validate key presence and basic request success
- expose one provider/model path clearly for `v1`
- add user-facing explanation of what data leaves the device when a provider is used
- design for future multi-provider support without requiring it in `v1`

#### Recommended V1 Constraint

- ship with one provider first
- add a second provider only after the first path is solid

#### Output

- a user can configure a provider key and use the app without engineering help

### 6. In-Scope Assistant And Retrieval

This is the core product loop missing from the prototype.

#### Status Now

- **not started**
- there is no real in-scope assistant/session surface yet
- current receipts are prototype memory surfaces, not durable retrieval-event receipts

#### Required

- implement an in-scope assistant/session surface
- support user turns inside a scope
- assemble context from:
  - recent scope memory
  - configured categories
  - pinned priorities
  - relevant source-derived items
- implement retrieval receipts tied to actual retrieval events
- ensure excluded memories are not reused once excluded
- make memory mode behavior real
  - `Scope only`
  - `Scope + global`
  - `Manual only`
  - `Temporary` if retained for `v1`
- log enough retrieval metadata to explain why an item was used

#### Confidence And Trust Requirements

- confidence extraction should remain the driver for consequential automation
- every automatic action should be:
  - silent if very safe
  - recoverable if medium confidence
  - reviewed if low confidence

#### Output

- a user can ask inside a scope and understand why the answer used what it used

### 7. Scope Lifecycle And Core UX Completion

The app needs to feel complete enough for daily use.

#### Status Now

- **partial**
- create and open scope flows exist
- empty state direction is strong
- rename, archive/delete, and real-use settings are still incomplete

#### Required

- create scope flow
- open scope flow
- rename scope
- archive or delete scope
  - either implement `Archived` or remove it from `v1`
- make empty states and first-run states feel intentional
- finish settings needed for real use
  - timestamp display toggle
  - provider settings
  - potentially media/storage preferences if needed
- remove all remaining prototype-only rough edges in the main path

#### Recommended

- keep settings minimal
- prefer smart defaults over exposing every configuration knob in `v1`

#### Output

- the app feels like a usable product, not a prototype demo

### 8. Onboarding And Trust Copy

`v1` needs onboarding that explains the mental model and data posture clearly.

#### Status Now

- **not started**
- some calm inline copy exists, but there is no first-run onboarding or trust explainer flow yet

#### Required

- first-run introduction to what a `scope` is
- first-run path to create the first scope
- just-in-time explanation for BYO key setup
- just-in-time explanation for microphone and photo access
- concise trust copy for:
  - what is stored locally
  - what is sent to a provider
  - how `Auto-scope` behaves
  - how to correct automation
- ensure the app uses terse, calm copy consistently

#### Output

- new users understand the product without reading a manual

### 9. Privacy, Settings, And App Store Readiness

Even if the first ship is TestFlight-first, these requirements should be handled as part of `v1`.

#### Status Now

- **early**
- microphone usage copy exists
- photo-library privacy strings, policy materials, store disclosures, and release assets are still missing

#### Required

- permission usage strings for microphone, photos, and any relevant media access
- privacy policy draft
- App Store privacy disclosure inputs prepared
- clear handling for BYO provider data sharing
- app icon
- launch assets and baseline branding assets
- basic App Store/TestFlight metadata draft

#### Recommended

- make a release checklist for:
  - app version bump
  - test notes
  - known limitations
  - screenshots

#### Output

- the repo is not blocked on basic release hygiene when the product is ready

### 10. Quality, Testing, And Release Gating

The current build verifies compilation. `v1` needs broader confidence.

#### Status Now

- **early**
- the repo currently has build verification but no meaningful automated test coverage for the `v1` gates yet

#### Required

- unit tests for:
  - auto-scope confidence mapping
  - waiting-on confidence mapping
  - persistence save/load behavior
  - exclusion behavior
  - retrieval assembly rules
- targeted UI tests for:
  - create scope
  - capture and save
  - relaunch and persistence
  - in-scope ask and receipts
- manual QA checklist across:
  - first run
  - denied permissions
  - no provider key
  - corrupted or missing asset edge cases
  - long scope titles
  - large memory counts
- performance sanity pass on real device
- at least one external TestFlight pass before calling `v1` ready

#### Output

- a release candidate that is more than “builds on simulator”

## Execution Order

Recommended order:

1. scope freeze and `v1` cut line
2. durable data foundation
3. real capture plumbing
4. derivation and memory processing
5. BYO provider setup
6. in-scope assistant and retrieval
7. scope lifecycle and onboarding polish
8. privacy/release readiness
9. testing and TestFlight gating

## Next Milestone

The next milestone is `2. Durable Data Foundation`.

This comes next because:

- persistence is the trust gate between prototype and product
- real capture should not be built on top of throwaway in-memory state
- receipts, retrieval, and assistant sessions all need durable records underneath

### Exit Criteria

We can call this milestone complete when:

1. the app launches from persisted records rather than required seed data
2. scopes and categories survive relaunch
3. note capture saves durably before dismissal
4. recent memory and receipts surfaces read from persisted records
5. there is a filesystem-backed home for original assets, even if audio/image ingestion is completed in the next milestone

### First Slice

Start with this implementation slice:

1. stand up the `SwiftData` container and storage coordinator
2. persist `Scope`, `ScopeCategory`, `MemoryItem`, and `SourceAsset` records
3. load the app from persisted state on launch
4. make scope creation and note capture durable first
5. leave seed data behind a debug/bootstrap path rather than the default app path

## Hard Ship Gates

Do not call `v1` done unless all of these are true:

- no critical path depends on in-memory mock state
- no primary UI advertises placeholder functionality
- text, audio, and image capture are real and durable
- a scope-based assistant flow is real
- retrieval receipts reflect actual retrieval events
- key trust flows are recoverable
  - auto-scope correction
  - waiting-on undo or review
  - exclusion respected
- the app works cleanly after relaunch
- BYO key setup works for at least one provider
- permissions and privacy copy are in place
- the app passes a manual TestFlight-ready checklist

## Suggested Cut Strategy If Schedule Tightens

This document already cuts `video` from `v1`.

If `v1` starts growing, cut in this order:

1. advanced retrieval tuning UI
2. non-essential visual flourishes
3. secondary provider support
4. deeper settings

Do **not** cut:

- durable persistence
- real audio capture
- real image capture
- BYO key flow
- real receipts
- correction paths for automation

## After V1

Already planned after `v1`:

- `v1.1`: `video` capture, `link` capture, and any remaining non-essential retrieval tuning UI
- `v1.5`: iCloud sync, export/import, migration and recovery UX
- `v2`: dedicated memory review workflows
