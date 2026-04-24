# Scope-First Memory App — V0 Brief

**Date:** 2026-04-22
**Status:** Draft
**Prepared by:** Codex
**Codename:** `Scope`

---

## TL;DR

Build an iPhone-first AI workspace where the primary object is a **scope**, not a chat.

Each scope acts like a persistent context container for a hobby, project, life area, or ongoing interest. The app should help the user drop back into that scope instantly, with memory boundaries that are explicit, inspectable, and user-controlled.

The wedge is not "AI chat with memory." The wedge is:

- scope-first navigation
- visible and editable memory
- configurable memory collection
- configurable memory retrieval
- BYO provider keys
- calm, intentional UX that feels personal rather than enterprise

---

## 1. Product Thesis

People do not think about their lives as one endless conversation. They think in ongoing containers:

- "my reading life"
- "that startup idea"
- "the pottery rabbit hole"
- "family travel planning"
- "my health questions"

Current AI tools mostly treat those as chats, folders around chats, or projects with opaque memory. This creates friction every time a user wants to return to something ongoing. The app should make re-entry feel like resuming a room that is already arranged for that part of life.

### Core belief

AI memory should be:

- scoped
- legible
- editable
- optional
- owned by the user
- shapeable to the domain of each scope

---

## 2. Product Promise

**One-line promise:**
An AI workspace that remembers by scope, not by accident.

**User promise:**
When I return to a scope, the app should feel oriented, grounded, and trustworthy. I should understand what it knows, why it knows it, and how to change that.
The default flow should feel low-friction, with deeper controls visible and configurable on demand rather than forced into every interaction.
By default, the product should optimize for speed and minimalism. If an action can be automated with usefully high accuracy, it should be. Manual adjustments and checking should remain available, but as an extra hop unless the user chooses to surface them more often.
Primary surfaces should communicate useful outcomes, not abstract system state. If background work creates something worth knowing, the app should surface the result in user language, not just report that memory or processing happened.
Where confidence can be extracted from model output or system logic, that confidence should drive what happens next: silent automation when confidence is high, quiet heads-up when confidence is medium, and manual intervention when confidence is low.

**Open-source promise:**
The project should be useful without a mandatory hosted subscription. Users can bring their own API keys, inspect the behavior, keep durable copies of their data under their control, and self-host optional backend pieces later if they want.

### Ownership posture

This product should be **ownership-first**, not dogmatically local-first.

That means:

- the user should not lose their data if they lose their phone
- the user should be able to move to a new device with minimal friction
- the user should not be locked into a vendor-hosted memory system they cannot inspect or leave

V1 should optimize for:

- durable copies
- smooth device migration
- exportability
- clear user control over where sensitive data lives

---

## 3. Target User

Primary user for v1:

- a thoughtful individual user
- comfortable with AI tools and API keys
- managing multiple long-lived interests or projects
- wants better continuity than normal chat apps
- cares about privacy, clarity, and control

This includes founders, researchers, hobbyists, writers, indie makers, and intellectually curious generalists.

V1 is not designed for:

- enterprise team rollout
- children or family sharing
- social collaboration
- heavy autonomous agents

---

## 4. Core Concepts

### 4.1 Scope

A long-lived container for a theme, project, interest, or domain.

Examples:

- `Book Notes`
- `Photography`
- `Cocktails`
- `Founder Ideas`
- `Japan Trip`
- `Strength Training`

### 4.2 Memory Modes

Each scope chooses one memory posture:

- `Scope only`: use only memories captured inside this scope
- `Scope + relevant global`: prefer scope memory, allow relevant global pull
- `Manual only`: only use memories the user explicitly saved
- `Temporary`: no durable memory accumulation

### 4.3 Memory Items

Atomic saved context units. Examples:

- a note
- a clipped link
- a photo
- a voice memo transcript
- a highlighted insight from a prior session
- a user-authored profile fact

Each memory item should show:

- source
- timestamp
- scope
- category
- why it may be useful
- current status: active, excluded, archived

### 4.4 Suggested Memory Categories

Each scope should propose a small set of relevant memory categories based on its type, name, and early usage.

Examples:

- `Book Notes`: authors, books, quotes, themes, questions, follow-ups
- `Japan Trip`: dates, places, lodging, restaurants, transport, ideas
- `Strength Training`: goals, lifts, injuries, routines, constraints, milestones
- `Founder Ideas`: products, problems, audiences, positioning, experiments, references

These categories are not rigid taxonomy. They are working rails that help the app decide:

- what is worth storing
- how to label saved memory
- what to prioritize during retrieval
- what to show the user when editing or reviewing memory

Users should be able to:

- accept suggested categories
- rename them
- disable them
- add their own
- pin a few as high-priority for retrieval

### 4.5 Retrieval Configurability

Retrieval should be configurable per scope, not only on/off.

At minimum, each scope should be able to tune:

- which categories are eligible for retrieval
- which categories are high priority
- whether light global memory can fill gaps for certain categories
- whether user-authored memories outrank inferred memories
- how aggressive retrieval should be overall

This should make the system feel guided rather than mysterious: the app is not just "remembering things," it is remembering according to a visible shape the user can refine.

These controls should follow progressive disclosure:

- default retrieval should work well without setup
- suggested categories should provide a sensible starting point
- advanced tuning should be easy to find, but not required to use the app well
- users should feel invited into control, not burdened by configuration

### 4.6 Retrieval With Receipts

When the assistant uses saved context, the app should show why it was pulled.

The user experience should answer:

- what context was used
- whether it came from this scope or global memory
- which category caused it to be eligible
- how to remove or demote it

### 4.7 Confidence-Gated Automation

When the app is making a consequential decision on the user’s behalf, it should not treat every level of certainty the same.

The default policy should be:

- `High confidence`: apply automatically; the user does not need to see it in the main path
- `Medium confidence`: apply automatically, but show a quiet notification with a one-tap correction path or dismiss
- `Low confidence`: do not apply automatically; show a one-tap path into manual assignment or confirmation

This is especially important for:

- auto-scope
- resolving `waiting on` items
- future retrieval and memory-promotion decisions

This policy should be architected so it can become user-configurable later.
V1 does not need visible settings for this, but the product should not hard-code a single irreversible behavior model.

---

## 5. Design Foundation

V1 should not look like enterprise software or a generic chat wrapper.

### Brand language

The product should feel:

- calm
- thoughtful
- literate
- tactile
- grounded
- quietly capable

Avoid:

- hyper-productivity aesthetics
- neon AI futurism
- dashboard clutter
- playful-but-vague whimsy

### Design principles

1. **Re-entry over novelty**
   The most important moment is coming back to a scope and instantly feeling oriented.
2. **Clarity over magic**
   If memory is used, the app should reveal enough for the user to trust it.
3. **Soft focus, sharp hierarchy**
   The interface can feel warm and atmospheric, but interaction choices must stay crisp.
4. **One strong idea per screen**
   Home is for scopes. Scope detail is for working inside a scope. Memory settings are for control.
5. **Native dignity**
   Use iOS conventions where they help, not because they are default, but because they reduce friction.
6. **Guided structure, not hard taxonomy**
   Categories should help the user think and retrieve better, without turning the product into a database they have to maintain.
7. **Low friction by default, visible control on demand**
   The primary path should stay fast and calm. Configuration should be discoverable and powerful, but never dumped into the main flow all at once.
8. **Useful outcomes over internal status**
   The app should prefer signals like `1 new research briefing` or `choose primary audience` over abstract labels like `2 memories ready`.

### Visual direction

- iPhone-first
- editorial and shelf-like, not dashboard-like
- restrained color system with one warm signature accent
- expressive typography with strong hierarchy
- gentle motion and transitions that reinforce continuity
- cards and surfaces should feel like curated objects, not generic panels

---

## 6. V1 Product Scope

### Must have

- create, rename, archive, and reorder scopes
- enter a scope and see its current context at a glance
- chat or work inside a scope
- one-tap voice capture from the app home or active scope
- save memory items manually
- basic memory visibility and exclusion controls
- choose memory mode per scope
- generate and edit suggested memory categories per scope
- tune retrieval eligibility and priority by category
- support BYO API keys for at least 1-2 providers
- show retrieval receipts when saved context is used
- local-first storage for core data
- share sheet capture into a chosen scope
- auto-scope capture started outside a scope, with easy override
- keep advanced memory and retrieval controls accessible without making them part of the default flow
- surface background memory/agent results as concrete user-meaningful updates rather than internal system counters

### Should have

- voice memo capture
- scope icon / cover customization
- search across scopes and memories
- pinned memory items
- onboarding that teaches memory modes clearly

### Explicitly out of scope for v1

- Android
- collaboration or shared scopes
- public feeds or social discovery
- autonomous background agents
- dedicated memory review workflows
- Gmail / calendar / Slack connectors
- hosted billing
- broad plugin ecosystem

---

## 7. Technical Direction

### App stack

- `SwiftUI` for the iOS app
- `SwiftData` or a lightweight local persistence layer for on-device data
- `Keychain` for provider API keys
- app architecture designed to support future app extensions and widgets cleanly

### API model

BYO keys should be a first-class path, not a hidden advanced setting.

Recommended v1 approach:

- direct provider calls from device for personal use
- local secure key storage in Keychain
- provider abstraction layer so OpenAI / Anthropic / others can be swapped
- optional relay interface designed in from the start, but not required for v1 launch

This keeps the app useful as an open-source personal tool while avoiding premature infrastructure.

### Data model posture

Store locally:

- scopes
- memory items
- scope category configurations
- session metadata
- user preferences
- retrieval events

Local persistence should be treated as a working copy, not necessarily the only durable copy.

Do not require:

- cloud account
- hosted auth
- proprietary sync

But do plan for:

- cloud-backed duplication for users who want durable off-device copies
- near-zero-friction transfer to a new device
- explicit export / import paths over time

Planned sequencing:

- `v1`: local working copy with strong ownership-oriented architecture
- `v1.5`: iCloud sync plus export/import as the first durability fast follow

---

## 8. Repo Shape

Suggested initial repo layout:

```text
scope/
  apps/
    ios/
  packages/
    core-models/
    provider-kit/
    prompt-kit/
  docs/
    product-brief.md
    design-foundation.md
    core-data-model.md
    tech-stack.md
    roadmap.md
  assets/
    brand/
    app-store/
```

Notes:

- `core-models` should define scopes, memories, sessions, and retrieval records
- `provider-kit` should normalize model providers and key handling
- `prompt-kit` should stay thin and deterministic; this product is not a prompt playground
- `docs/` should remain lightweight but deliberate from the start

---

## 9. Milestones

### Milestone 0 — Foundation

- finalize product name or keep codename
- lock design principles
- define information architecture
- create clickable prototype for 4 key screens

### Milestone 1 — Local-first shell

- app shell
- scope list
- scope detail
- local persistence
- basic design system tokens

### Milestone 2 — Memory control

- basic memory visibility and exclusion controls
- memory modes
- suggested memory categories per scope
- retrieval tuning by category
- receipts UI
- search and pinning basics

### Milestone 3 — AI integration

- BYO key onboarding
- first provider integration
- scoped context assembly
- assistant responses inside scope

### Milestone 4 — Capture polish

- share sheet
- voice memo path
- onboarding refinement
- visual polish pass

---

## 10. Success Criteria For V1

V1 is successful if a single user can:

1. create 3-5 meaningful scopes
2. return to any one of them after a few days and feel immediately re-oriented
3. understand what memory is being used and why
4. shape what gets remembered and retrieved by editing scope categories
5. bring their own provider key without friction
6. trust the app enough to keep using it for real life, not just demos
7. use the app effectively without being forced through setup-heavy configuration screens

---

## 11. Open Questions

Questions to answer before implementation starts:

- final product name
- whether "scope" is the shipped term or only an internal concept
- which two providers to support first
- whether widgets belong in v1.1 or later

---

## 12. Recommendation

Proceed with an iPhone-first SwiftUI repo built around a local-first core, first-class BYO keys, and a design-led scope model.

The differentiator should be treated as a product system, not a feature list:

- scope-first structure
- inspectable memory
- personal trust
- consistent design language

If execution stays disciplined, this can be both a genuinely useful personal tool and a credible open-source founder project.
