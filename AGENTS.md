# Scope — Agent Reference

## North Star

**Remember by scope, not by accident.**

`Scope` is an iPhone-first AI workspace built around persistent scopes rather than chat threads. Every meaningful product or engineering decision should support:

- fast re-entry into an ongoing part of life
- visible trust
- calm, minimal UX
- user ownership over memory and data

If a change makes the app feel more like a generic AI console, admin dashboard, or chat wrapper, it is probably moving in the wrong direction.

**Tiebreaker:** trust.  
When in doubt, prefer the option that feels more legible, more recoverable, and less surprising to the user.

## Founder Context

The Founder is a solo founder. Time and cognitive bandwidth are scarce.

Work should respect that:

- Default to doing, not asking, when the tradeoff is low-risk.
- Make outcomes easy to verify quickly.
- Surface only the decisions that genuinely need product judgment.
- Keep communication concrete and concise.
- Protect the repo from turning into an internal agent transcript.

## Workflow

Follow this workflow for any non-trivial change:

1. work in an isolated git worktree
2. make changes in a branch, not directly in the main clone
3. run the relevant verification step
4. have a subagent review the work before merge
5. if review is clean, merge to local `main`
6. push `main` to `origin/main`

Do not leave approved work sitting only in a side branch.

### Worktree rule

Never edit the main clone directly for implementation work.

Suggested pattern:

```bash
cd /Users/fatimaabdulah/scope
git worktree add ../scope-codex-<slug> -b codex/<slug>
cd ../scope-codex-<slug>
```

When the work is complete and safely merged, clean up the worktree:

```bash
git worktree remove ../scope-codex-<slug>
```

### Review rule

Before merging meaningful code changes, use a subagent or separate review pass to check for:

- trust regressions
- UX inconsistency
- unnecessary complexity
- code quality issues
- misleading status or automation behavior

Do not skip review just because the change is small if it touches user-facing behavior.

### Merge rule

Once review is clean:

- merge into local `main`
- push `main` to `origin`

This repo should not accumulate stale “done but unmerged” branches.

## Product Principles

These are not just design preferences. They should shape implementation decisions too.

- **Scope-first, not chat-first.**
  `Scope` is the primary object. Chats, sessions, and captures live inside that model.
- **Speed and minimalism by default.**
  If something can be handled well automatically, do it. Manual control should exist, but usually one layer deeper.
- **Useful outcomes over system state.**
  Prefer user-meaningful signals like `1 new research briefing` over internal status like `memories ready`.
- **Confidence should drive behavior.**
  High confidence: apply silently.  
  Medium confidence: apply with a quiet heads-up and one-tap fix.  
  Low confidence: do not apply automatically; require manual review.
- **Ownership-first, not dogmatically local-first.**
  Local working copies are good. Durable copies and portability matter more.
- **Calm defaults, visible control.**
  The app should never feel like a settings panel first.

## Current State

This repo currently contains:

- a working `SwiftUI` iOS prototype under `apps/ios/Scope`
- public product, design, architecture, and roadmap docs under `docs/`
- placeholder package folders under `packages/`

Current implemented prototype behavior includes:

- scope-first home with hierarchical cards
- scope detail with receipts and lightweight controls
- one-tap audio entry
- unified text/image/video capture composer
- confidence-based auto-scope
- confidence-based `waiting on` resolution
- post-save in-app notices with fix, undo, or review paths

Still intentionally mocked or incomplete:

- real microphone recording
- real image/video pickers
- durable persistence beyond in-memory state
- provider integration
- retrieval engine beyond prototype logic

The single best source of truth for current functionality is:

- `docs/feature-status.md`

## Public vs Private Docs

This repo is public. Keep the public surface intentional.

Public docs belong in `docs/` and should be durable:

- product brief
- design foundation
- data architecture
- core data model
- tech stack
- roadmap
- feature status

Private local-only docs belong in `.private-docs/`.

Do **not** commit:

- agent planning notes
- iteration scratch docs
- wireframes that are only for local working sessions
- implementation transcripts
- temporary exports or screenshots

If new planning docs are useful only to the Founder locally, place them in `.private-docs/`, not `docs/`.

## Project Structure

```text
scope/
  AGENTS.md
  README.md
  apps/
    ios/
      Scope/
  docs/
  assets/
    brand/
  packages/
    core-models/
    provider-kit/
    prompt-kit/
  .private-docs/
```

### Important paths

- `apps/ios/Scope/Scope/` — app source
- `apps/ios/Scope/Scope/State/AppModel.swift` — main prototype store and orchestration
- `apps/ios/Scope/Scope/Models/ScopeModels.swift` — app-facing model layer
- `apps/ios/Scope/Scope/UI/Theme/Theme.swift` — design system primitives
- `docs/` — public project docs
- `.private-docs/` — ignored local planning docs

## Stack

- `SwiftUI` for UI and navigation
- `Observation` for app state
- in-memory prototype state today
- intended path toward `SwiftData` + durable asset storage
- iPhone-first, Apple-native implementation bias

Do not introduce unnecessary abstraction just because it feels “architecturally pure.”  
This project should stay clean and reusable, but not prematurely enterprise-shaped.

## Build And Verification

From repo root:

```bash
xcodebuild -project apps/ios/Scope/Scope.xcodeproj -target Scope -sdk iphonesimulator build
```

Typical simulator install / launch:

```bash
xcrun simctl install booted /Users/fatimaabdulah/scope/apps/ios/Scope/build/Release-iphonesimulator/Scope.app
xcrun simctl launch booted com.fatimaabdulah.scope --terminate-running-process
```

When making app changes, build before declaring the work done.

## Implementation Rules

- Keep shared behavior centralized.
  Confidence-policy logic, notices, and trust-related action routing should live in reusable model or shared UI layers, not duplicated per screen.
- Preserve the product language.
  Use `scope`, `auto-scope`, `used in this reply`, `source details`, and similar established phrases unless there is a clear reason to change them.
- Avoid exposing internal machinery on primary surfaces.
  The app should not narrate its own processing unless the user needs that information.
- Respect the design direction.
  This product should feel editorial, sharp, and deliberate, not glossy enterprise AI.
- Reuse components when the pattern already exists.
  Do not fork the notice system, capture footer patterns, dock patterns, or card language casually.
- Keep future configurability in mind.
  Some controls are intentionally not exposed yet, but the model layer should be designed so they can be exposed later without a rewrite.

## Design And Trust Rules

When touching UI or flow logic, preserve these rules:

- If an action can be clearly communicated with an icon, prefer the icon.
- Prefer terse copy.
- Default flows should feel one-tap or near-one-tap whenever possible.
- High-confidence automation should usually disappear into the background.
- Medium-confidence automation should be recoverable.
- Low-confidence automation should stop and ask for review.
- Receipts and visibility controls should make the app feel more trustworthy, not more complicated.

## Release Hygiene

- Keep `.gitignore` up to date for build products, temp files, and local-only docs.
- Do not commit Xcode build output.
- Do not commit `.private-docs/`.
- If the public README or public docs become misleading after a feature change, update them as part of the work.

## Near-Term Priorities

1. Real audio capture
2. Real image/video pickers
3. Durable persistence
4. Provider integration
5. Retrieval plumbing
6. `v1.5` sync and export

## If You Are Unsure

Use this order:

1. Check `README.md`
2. Check `docs/feature-status.md`
3. Check `docs/design-foundation.md`
4. Check `docs/product-brief.md`
5. If the decision is still ambiguous, prefer the more minimal and more trustworthy option
