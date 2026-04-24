# Scope

An iPhone-first AI workspace that remembers by scope, not by accident.

## What This Repo Is

This repo is the home for a personal-first, open-source AI product centered on:

- scope-first navigation instead of chat-first navigation
- user-owned memory
- configurable retrieval
- BYO provider keys
- calm, deliberate product and design execution

## Current Status

This project is now in an early `v0` prototype phase: the iOS shell is up, the core scope surfaces exist, and the trust layer around capture and follow-up handling is live in prototype form.

Current implemented prototype behavior:

- scope-first home with hierarchical cards
- scope detail with receipts and lightweight controls
- one-tap audio entry
- unified text/image/video capture composer
- confidence-based `Auto-scope`
- confidence-based `waiting on` resolution
- post-save in-app heads-up notices with quick fix or review paths

The initial docs live in [`docs/`](./docs):

- `core-data-model.md`
- `data-architecture.md`
- `product-brief.md`
- `design-foundation.md`
- `feature-status.md`
- `tech-stack.md`
- `roadmap.md`

Local iteration notes, wireframes, and implementation planning docs are intentionally kept out of the public repo.

## V1 Shape

The first version is intended to be:

- iPhone-first
- built with `SwiftUI`
- ownership-first
- designed around persistent scopes, memory categories, and retrieval receipts

## Near-Term Priorities

1. Connect audio capture to real recording state
2. Connect image/video controls to real pickers
3. Replace in-memory state with SwiftData plus durable asset storage
4. Introduce provider integration and retrieval plumbing
5. Add `v1.5` sync/export

## Run The Prototype

Build in Xcode:

- open `apps/ios/Scope/Scope.xcodeproj`
- run the `Scope` target in an iPhone simulator

Or from the command line:

```bash
xcodebuild -project apps/ios/Scope/Scope.xcodeproj -target Scope -sdk iphonesimulator build
```
