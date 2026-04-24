# Data Architecture

## Recommendation

For image and audio support in v1, the strategy should be:

- keep the original source asset
- derive structured artifacts from it
- retrieve mostly from the derived artifacts
- let the user inspect the source when needed

This is a hybrid approach.

We should **not** build v1 around "save summaries only."
We should also **not** make retrieval depend on dragging raw media into every prompt.

The right shape is:

- broad capture
- selective extraction
- structured memory
- source-backed trust

This should now be read through an **ownership-first** lens:

- the app keeps a local working copy
- the user should have a durable off-device copy when they want one
- device loss should not mean memory loss
- migration to a new phone should be low-friction

## Why Summaries Alone Are Not Enough

If the app stores only summaries or extracted highlights:

- the user loses the original source of truth
- later improvements in extraction cannot recover lost detail
- category rules cannot be re-run on the original asset
- the system becomes harder to trust when a summary is wrong or incomplete
- valuable nuance gets flattened too early

For this product, that would weaken both usefulness and credibility.

## Why Raw Media Alone Is Not Enough

If the app treats raw images and audio files as the primary memory substrate:

- retrieval becomes expensive and noisy
- scope memory becomes harder to inspect
- performance degrades as media piles up
- the app becomes too dependent on provider-specific multimodal behavior

Raw media should be retained, but it should not be the default unit of retrieval.

## V1 Model

### 1. Original Asset

Store the original user-provided media:

- image file
- audio recording
- imported document or attachment where relevant

These should live in the app's file storage, not as large inline database fields.

Purpose:

- preserve source of truth
- allow reprocessing later
- support user inspection and trust

### 2. Derived Artifacts

Generate one or more machine-usable representations from the source.

For images:

- OCR text
- caption or scene summary
- extracted entities
- dates, places, names, products, objects when relevant

For audio:

- transcript
- condensed summary
- extracted entities
- possible facts, tasks, dates, references, and preferences

Purpose:

- make retrieval fast and understandable
- map source material into memory categories
- support future ranking and filtering

### 3. Structured Memory Records

Promote the most useful extracted content into normalized memory items tied to:

- a scope
- one or more categories
- source references
- confidence / review state

These are the records that should power most of the app's visible memory system.

### 4. Retrieval Records

Whenever the assistant uses saved context, log:

- which memory items were selected
- which categories influenced selection
- whether the source was local or global
- which asset or transcript the memory came from

This supports receipts and future tuning.

## Storage Split

### Persistent Stores We Support In V1

V1 should support three persistent stores, each with a clear job:

1. `SwiftData DefaultStore`
2. `Filesystem in the app group container`
3. `Keychain`

And it should be designed to support a fourth layer cleanly:

4. `Cloud-backed sync / durability`

This should be treated as one architecture, not three competing options.

Planned sequencing:

- `v1`: ship the first three stores
- `v1.5`: add the cloud-backed durability layer

### Canonical Persistence Model

The canonical durable layout for v1 should be:

- `SwiftData DefaultStore` as the local working database
- `App Group` filesystem storage as the local artifact store
- `Keychain` as the secrets store
- `Cloud-backed user storage` as the durability and migration layer when enabled

In practice:

- the local database tracks scopes, categories, memories, retrieval events, and artifact metadata
- the local artifact store holds original media files and larger derived outputs needed on device
- the secrets store holds provider credentials
- the cloud layer holds synced copies or mirrored state for recovery and device transfer

This gives us:

- fast local interaction
- clean support for share extensions later
- a database that stays queryable
- preserved source material for reprocessing
- durable copies beyond a single phone

## Ownership-First Sync Direction

For this product, the right long-term posture is not "local only."

The better posture is:

- local working copy for speed and offline use
- cloud-backed duplication for durability
- explicit export/import for portability

### Apple-Native First Option

The most natural first sync path on iPhone is `CloudKit`, planned here as the `v1.5` implementation target.

Apple documents that:

- SwiftData can sync model data across a person's devices using iCloud
- CloudKit private databases are user-private by default
- data in the private database counts toward the user's iCloud storage

This makes CloudKit a strong candidate for:

- structured user data
- low-friction device migration across Apple devices
- durable off-device copies without introducing our own hosted account system

### Portability Principle

Cloud-backed durability is not enough by itself.

To satisfy the ownership goal, the product should also aim for:

- exportable user data
- import on a new install
- the ability to leave the app without losing the user's memory history

So the guiding principle should be:

- `sync for convenience`
- `export for ownership`

### SwiftData

Use SwiftData for:

- scopes
- memory categories
- memory items
- session summaries
- retrieval events
- asset metadata
- links from memories to source assets

For v1, this should use the `DefaultStore`, which Apple documents as SwiftData's default Core Data-backed store.

Important boundary:

- SwiftData stores structured records and lightweight text we want to query often
- SwiftData does not become the home for all raw media or every large extraction blob

Suggested examples that can live in SwiftData:

- scope names and settings
- category definitions and retrieval priority
- promoted memory items
- short summaries
- short OCR excerpts
- retrieval receipts
- artifact identifiers and file paths
- processing status and extraction version

### Filesystem / App Group Container

Use file storage for:

- original images
- original audio files
- large transcripts if needed
- derived text artifacts that may grow large over time

This keeps the core database lighter and prepares us for share extensions later.

For v1, this should be the durable home for permanent source-backed artifacts.

Suggested layout:

```text
AppGroupContainer/
  Database/
    Scope.store
  Assets/
    <asset-id>/
      original.<ext>
      transcript.txt
      summary.json
      extraction.json
      thumbnails/
```

This means the permanent artifact package for a source item lives on disk as a small folder, while SwiftData keeps the index and relationships.

Recommended rule of thumb:

- if it is a large binary or long-form derived payload, keep it on disk
- if it is structured, query-heavy, and frequently filtered, keep it in SwiftData

### What Is The Source Of Truth?

The source of truth should be split by data type:

- the local `SwiftData` store is the source of truth for on-device structured product state
- the local `artifact filesystem` is the source of truth for on-device raw media and large derived outputs
- `Keychain` is the source of truth for secrets

When cloud sync is enabled:

- the cloud layer becomes the durable mirrored copy for supported records and assets
- the app should reconcile local and remote state, not pretend one phone is the only canonical home of the user's data

This is intentional. We do not need one monolithic store.

Instead, each persistent layer should own the data type it is best suited for.

### Keychain

Use Keychain for:

- BYO provider keys

This includes:

- provider API keys
- future relay tokens, if we add them

Keys should not be duplicated into SwiftData or file storage.

## Derived Artifact Persistence

Permanent derived artifacts should not all be treated the same.

### Persist in SwiftData

Persist in SwiftData when the artifact is:

- short
- structured
- frequently queried
- important to filtering or ranking

Examples:

- promoted facts
- extracted dates
- tagged preferences
- category assignments
- short normalized summaries

### Persist on Disk

Persist on disk when the artifact is:

- large
- append-heavy
- multimodal
- useful for reprocessing more than direct querying

Examples:

- full transcript
- OCR dump
- extraction JSON
- waveform or timing metadata
- image thumbnails

### Practical Rule

Every source asset should get:

- a durable asset folder on disk
- a `SourceAsset` record in SwiftData
- zero or more `DerivedArtifact` records in SwiftData that point to either inline structured data or disk-backed payloads
- zero or more promoted `MemoryItem` records used by retrieval

## Retrieval Strategy

Default retrieval should prioritize:

1. user-authored memory items
2. reviewed or promoted extracted memories
3. category-matched derived artifacts
4. light global memory, if enabled for the scope

Default retrieval should **not** prioritize:

- raw full transcripts
- raw images
- raw audio blobs

Those should remain available as backing context, but not as the first thing pulled into every response.

## UX Principle

The default flow should stay low-friction:

- user captures an image or audio note
- app extracts useful structure automatically
- app suggests categories or promoted memories
- user can keep moving without manual cleanup

On demand, the user should be able to:

- inspect the original asset
- edit the summary
- delete the asset
- exclude certain extracted memories
- rerun extraction later
- change the categories that matter for retrieval

## V1 Recommendation

Plan for image and audio support as first-class source types in v1.

But plan retrieval around **derived structured memory**, not around passing raw media through the system every time.

In shorthand:

- retain broadly
- retrieve selectively
- summarize carefully
- never lose the source

And at the product level:

- keep a local working copy
- provide durable off-device duplication
- make migration and recovery low-friction

## Future Direction

Later versions can add:

- embeddings or semantic indices for derived artifacts
- better reprocessing pipelines
- provider-specific multimodal enhancements
- cross-device sync for asset metadata first, then optionally assets

The important thing for v1 is to choose an architecture that preserves optionality without creating a heavy or noisy default experience.

## V1 Bottom Line

If we say this plainly:

- permanent source assets live on disk in the app group container
- permanent structured app state lives in SwiftData
- permanent secrets live in Keychain

That is the persistent-store strategy I would recommend for v1.
