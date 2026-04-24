# Design Foundation

## Purpose

This document defines the visual and interaction language for `Scope`.

It should keep the product from drifting into any of these traps:

- generic AI chat UI
- enterprise dashboard UI
- overdesigned concept work with weak usability
- settings-heavy information architecture that makes memory feel like admin work

The goal is not just "good taste." The goal is a design system that supports the product promise:

- fast re-entry
- calm confidence
- visible trust
- configurable depth without configuration burden

## Core Experience Goal

Returning to a scope should feel like stepping back into a room that already knows what belongs there.

The user should feel:

- oriented
- calm
- in control
- respected
- curious to continue

The app should feel like a personal workspace with memory, not like a chatbot shell with extra settings.

## Design Positioning

### Product metaphor

The closest design metaphor is not "assistant panel."

It is:

- shelf
- desk
- notebook margin
- study
- studio

This should create an interface that feels curated and inhabitable rather than transactional.

### Emotional tone

The product should feel:

- calm
- thoughtful
- literate
- tactile
- grounded
- quietly capable

Avoid:

- productivity maximalism
- loud futurism
- glossy AI spectacle
- cute whimsy with weak trust signals
- dense power-user clutter

## Brand Idea

### Core brand thought

The app helps people return to the parts of life they are already living.

This is not a machine for endless conversation.
It is a system for returning to meaningful continuity.

### One-line internal framing

`Scope` is a personal memory workspace that feels arranged, not accumulated.

### Brand language direction

Brand language should be:

- plainspoken
- warm
- intelligent
- unhurried
- precise without being clinical

Avoid copy that sounds:

- overly motivational
- robotic
- theatrical
- mystical
- "AI-native" in the worst sense

### Example copy posture

Prefer:

- `What matters here`
- `Used in this reply`
- `Suggested categories`
- `Keep original`
- `Source details`
- `Adjust retrieval`

Avoid:

- `Unlock intelligence`
- `Supercharge your workflow`
- `Memory graph`
- `AI magic`
- `Hyper-personal context engine`

## Design Principles

1. **Re-entry over novelty**
   The most important moment is coming back to a scope and instantly understanding where you are.
2. **Clarity over magic**
   If memory is used, the product should reveal enough for the user to trust it.
3. **Soft focus, sharp hierarchy**
   The atmosphere can be warm and quiet, but the structure must remain legible.
4. **Low friction by default**
   The core flow should work well with minimal setup.
5. **Visible control on demand**
   Advanced controls should be easy to find and safe to ignore.
6. **Automate when confidence is usefully high**
   If the product can make a strong, helpful decision, it should do so by default. But confidence should also determine what happens next: high-confidence decisions can stay invisible, medium-confidence decisions should come with a quiet heads-up, and low-confidence decisions should stop short of automatic application.
7. **Native dignity**
   Use iOS patterns where they reduce cognitive load and support polish.
8. **Structured, not bureaucratic**
   Categories and receipts should guide the user, not turn the product into a database admin tool.
9. **Trust is part of the interface**
   Source visibility, retrieval receipts, and memory controls are not secondary settings. They are part of the design language.
10. **Usefulness over system status**
   Primary surfaces should show what the user can act on or understand immediately, not internal pipeline states.

## Default Interaction Principle

By default:

- speed
- minimalism
- useful automation

If an action can be automated with usefully high accuracy, the product should do it.

Manual adjustments and checking should remain available, but they should usually require:

- an extra tap
- a disclosure
- an explicit user preference to keep them surfaced

This keeps the app from turning every interaction into a review step while preserving trust and control for users who want them.

## Confidence-Driven Automation

Where confidence can be extracted reliably enough to shape the next step, it should.

This is a first-level design principle, not an implementation detail.

The product should use a three-band model:

- `High confidence`: apply automatically and keep the UI quiet
- `Medium confidence`: apply automatically and show a calm heads-up with a one-tap fix or dismiss path
- `Low confidence`: do not apply automatically; instead surface a one-tap path into manual assignment or review

This is especially important for:

- auto-scope
- task or `waiting on` resolution
- future retrieval or promotion actions that can change user-visible state

The key design rule is that not every automated path should look the same.
The UI should reflect the confidence level of the underlying decision.

Another important constraint:

- this policy should be designed so it can be configured later
- v1 does not need to expose those controls yet
- the architecture should still support adjusting thresholds or behaviors in the future without redesigning the flow

## Primary Surfacing Rule

When deciding what to surface on a primary screen, prefer:

- concrete outcomes
- next-action cues
- user-meaningful summaries

Avoid surfacing abstract internal states unless the user asks for more detail.

Prefer:

- `choose primary audience`
- `1 new research briefing`
- `Used in this reply`

Avoid:

- `2 memories ready`
- `3 retrieval candidates`
- `background job complete`
- `sync finished`

The product should surface the result of system work, not merely the fact that work happened.
If a background process creates something useful, show the useful thing.
If the system has only internal state to report, keep it hidden by default.

## Visual Direction

### Overall look

The interface should feel editorial and shelf-like, not dashboard-like.

Think:

- warm paper tones
- crisp typography
- restrained contrast
- carefully framed cards
- tactile surfaces
- breathing room

Not:

- glowing gradients everywhere
- glassmorphism for its own sake
- packed sidebars
- bright metric dashboards
- floating chatbot bubbles dominating the screen

### Atmosphere

The visual atmosphere should suggest:

- a private place
- a small collection of meaningful things
- a space that improves with use

That means the app should look better with five well-used scopes than with fifty noisy objects.

## Color System

V1 should use a restrained palette with one warm signature accent and one quiet secondary accent.

### Suggested starter palette

- `Canvas`: `#F4EFE7`
- `Surface`: `#FBF8F3`
- `Elevated Surface`: `#F8F3EC`
- `Ink`: `#1F1A17`
- `Muted Ink`: `#6E665E`
- `Line`: `#DDD4C8`
- `Accent / Ember`: `#B65D3A`
- `Accent / Moss`: `#6C7A5C`
- `Info / Slate`: `#5F7384`
- `Warning / Ochre`: `#A37A2A`

### Color rules

- warm neutrals should carry most of the interface
- accent color should be sparse and purposeful
- state color should not overpower the tone of the app
- retrieval and trust cues should rely on tone plus label, not color alone
- avoid pure black and stark white unless needed for accessibility

### Usage guidance

- `Canvas` for page background
- `Surface` for default cards and sheets
- `Elevated Surface` for selected or focused sections
- `Ink` for primary text
- `Muted Ink` for metadata and explanatory text
- `Ember` for actions, focus moments, and selected category emphasis
- `Moss` for stable, trusted, or reviewed memory states

## Typography

Typography should do a lot of the brand work.

### Recommended direction

- `New York` for display and section emphasis
- `SF Pro` for UI, labels, body, and controls

This keeps the app distinctly Apple-native while still giving it an editorial personality.

### Type roles

- `Display`: used sparingly for scope titles, major empty states, and key landing surfaces
- `Section title`: used for structural anchors such as `What matters here`
- `Body`: used for summaries, notes, receipts, and settings explanations
- `UI label`: used for buttons, chips, tabs, filters, and metadata
- `Caption`: used for timestamps, provenance, and secondary context

### Typography rules

- do not overuse display serif text
- maintain strong contrast between scope title, active context, and metadata
- avoid tiny metadata walls
- prefer short lines and strong grouping over dense blocks

## Layout And Spacing

### Structural approach

Use generous spacing, clear sectioning, and stable vertical rhythm.

The product should never feel cramped, even when a scope contains a lot of memory.

### Layout principles

- each screen should have one primary idea
- sections should feel like curated modules, not stacked widgets
- cards should have clear containment and purpose
- headers should earn their space
- screens should read well without hidden navigation assumptions

### Spacing posture

- comfortable outer margins
- clear separation between section groups
- tighter spacing only inside small, obvious clusters like chip groups

## Surfaces And Components

### Surface language

Use surfaces that feel like objects on a desk:

- lightly tinted cards
- subtle borders
- low, soft shadows when necessary
- clear rounding, but not bubble-like

### Component posture

Components should feel calm and durable.

Avoid:

- oversized pills everywhere
- excessive segmented controls
- ornamental floating buttons without context
- glossy or heavily animated cards

### Core component families

- `Scope cards`
- `Context summaries`
- `Memory chips`
- `Receipt rows`
- `Source asset cards`
- `Category controls`
- `Settings rows`

### Component behavior rules

- every card should answer one clear question
- chips should summarize structure, not become the main interface
- disclosure rows should reveal depth without feeling technical
- settings should be grouped by user mental model, not implementation detail

## Iconography

Icons should be quiet and functional.

### Direction

- use SF Symbols where possible
- keep icon usage sparse
- when a control is universally understood in context, prefer the icon over a redundant text label
- use text when the action is ambiguous, uncommon, or high-risk
- use icons to support scanning, not branding theater

### Good icon roles

- capture type
- source type
- reviewed vs excluded state
- retrieval provenance
- scope cover fallback

## Motion

Motion should reinforce continuity and focus, not provide novelty.

### Motion goals

- make re-entry feel smooth
- help users understand state changes
- reduce abruptness when showing deeper controls

### Motion rules

- prefer subtle fades, lifts, and slides
- use short duration and low amplitude
- animate disclosure and focus shifts more than decorative elements
- avoid "AI thinking" animations that imply false intelligence

### Good motion moments

- opening a scope
- revealing retrieval receipts
- promoting a memory item
- switching between summary and details

## Content And Voice

### UI voice

The UI voice should sound:

- calm
- competent
- respectful
- clear

### Copy rules

- prefer terse, concise copy by default
- use short, direct labels
- if the UI element already communicates the type, the text should only carry the new information
- prefer explanation over hype
- explain what happened, not what the system believes about itself
- write for confidence, not performance theater

### Examples

Good:

- `Saved to this scope`
- `Suggested from recent notes`
- `Used because this scope prioritizes themes`
- `Original kept`
- `Review before using again`

Bad:

- `Memory optimized`
- `Context intelligence applied`
- `This was semantically promoted`
- `Neural understanding increased`

## Trust And Transparency Patterns

Trust is a first-class design system concern.

### Retrieval receipts

Whenever memory materially affects a reply, the UI should be able to show:

- what was used
- which category made it relevant
- whether it came from scope or global memory
- whether it was user-authored, extracted, or inferred
- how to exclude or adjust it

### Trust cues

Trust cues should be:

- visible
- calm
- non-alarming
- actionable

They should not feel like debug logs.

### Control posture

The user should feel:

- invited to inspect
- not forced to manage everything
- confident that deeper control exists if needed

## Information Architecture

### Primary navigation model

Home should begin with scopes, not chats.

The top-level information architecture should be:

1. `Home / Scope library`
2. `Scope detail`
3. `Capture`
4. `Memory controls`
5. `Settings`

### Default flow

The standard flow should be:

1. enter a scope
2. understand current context
3. continue the work or thought
4. optionally inspect or refine memory behavior

This preserves low friction while keeping controls visible on demand.

## Screen Direction

### 1. Home / Scope Library

Purpose:

- orient the user around the parts of life they return to

Must communicate:

- each scope is a durable place
- scopes have different textures and priorities
- re-entry is the primary action

UI guidance:

- prominent page title
- curated scope cards, not tiny list rows by default
- each card shows title, one-line orientation, and fresh context
- show light signals of activity, not dashboards
- avoid making recent chats the dominant surface

Ideal content on a scope card:

- scope name
- short summary of where the user left off
- only user-meaningful signals such as:
  - `confirm Kyoto hotel`
  - `1 new research briefing`
- optional freshness metadata only when the user chooses to surface it in settings

Avoid on the default card:

- category inventories
- memory mode tags
- internal status counts
- system-state summaries that do not help the user decide what to do next

### 2. Scope Detail

Purpose:

- provide the main working environment for one domain

Must communicate:

- what this scope is about
- what currently matters here
- what memory the app is leaning on
- where to continue

UI guidance:

- top area should orient, not overwhelm
- keep one primary input path
- surface current context before old conversation history
- use collapsible modules for receipts and deeper controls
- treat memory as part of the workspace, not a separate admin page

Suggested section order:

1. scope title and mode
2. what matters here
3. primary compose / ask area
4. recent useful memory
5. receipts and controls

### 3. Memory Controls

Purpose:

- allow the user to shape memory and retrieval behavior without leaving the product feeling heavy

Must communicate:

- categories are guides
- advanced control exists
- configuration is reversible

UI guidance:

- emphasize suggested categories first
- allow pin, rename, disable, and add
- use clear grouping by retrieval impact
- show short explanatory helper text
- avoid exposing internal technical language

### 4. Capture Flow

Purpose:

- make it easy to add something useful without derailing the user

Must communicate:

- what was captured
- where it will go
- what the app will do with it

UI guidance:

- voice capture should be one tap away from the app home or active scope
- lightweight review step
- scope selection should be fast when needed
- captures started outside a scope should use smart auto-scope suggestion by default
- auto-scope should feel assistive, not presumptuous, with an easy `Change` path
- high-confidence auto-scope can be invisible
- medium-confidence auto-scope should show a quiet heads-up with `Change` or dismiss
- low-confidence auto-scope should stop at manual assignment, not guess silently
- show a simple promise such as `We’ll extract what matters and keep the original`
- advanced extraction controls belong behind a secondary action

## Memory Visualization Rules

Memory should feel shaped, not dumped.

### How memory should appear

- as curated items
- as category-linked signals
- as recent or pinned context
- as receipts when used
- as concrete outcomes when background work produces something useful

### How memory should not appear

- as giant raw logs
- as a system status dashboard
- as one endless chronological dump
- as abstract counters without meaning on their own

### Category presentation

Categories should feel like lightweight rails, not taxonomic bureaucracy.

Rules:

- keep category counts small by default
- highlight only the most relevant categories in primary surfaces
- let advanced category editing live one layer deeper
- use category names that sound like human organizing language

## Accessibility

Accessibility should be part of the first visual pass, not a cleanup pass.

### Requirements

- strong color contrast
- dynamic type support
- touch targets with comfortable sizing
- motion that respects reduced motion settings
- icon-only controls are acceptable only when the surrounding context makes the action obvious
- retrieval receipts readable without dense tap exploration

## Anti-Patterns

Do not ship these patterns:

- chat bubbles as the dominant identity of the product
- a home screen that is mostly recent conversations
- too many chips competing for attention
- settings pages that read like admin consoles
- bright gradient hero treatments that fight the calm tone
- raw system internals exposed as UX
- memory language that feels spooky or manipulative

## First Prototype Requirements

The first clickable prototype should define:

1. the visual identity of the home screen
2. the structure of one scope detail screen
3. the disclosure pattern for receipts
4. the editing model for categories
5. the capture flow for image, audio, and note input

If those five pieces feel coherent, the rest of the product will have a strong enough foundation to build on.

## Design System Starter Tokens

These should guide the first implementation pass:

- `radius-card`: medium, not playful
- `radius-chip`: smaller than card radius
- `border-default`: soft warm line
- `shadow-elevated`: subtle and low blur
- `spacing-page`: generous
- `spacing-section`: clear and consistent
- `motion-standard`: short fade/slide
- `motion-disclosure`: softer reveal for details and receipts

## Open Questions

- whether `Scope` remains the shipped noun or becomes a quieter internal concept
- whether home cards should use imagery, texture, or purely typographic identity
- whether the accent color should lean warmer or more botanical
- how much conversation history should appear above the fold in scope detail
- whether memory receipts are always visible in compact form or only after a reply
