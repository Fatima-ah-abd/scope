# Tech Stack

## Recommendation

For v1, the stack should follow the product and design direction we already set:

- iPhone-first
- native-feeling UX
- ownership-first data
- low-friction defaults
- visible control on demand
- clean path to share extensions, shortcuts, widgets, and user-controlled durability later

That points to a deliberately simple Apple-native stack.

## V1 Stack

### App

- `SwiftUI` for app UI and navigation
- `Observation` for app state and view updates
- `SwiftData` for the local working database
- `URLSession` for provider networking
- `Keychain` for BYO API key storage

### Packaging

- Xcode app target for `apps/ios`
- local Swift packages for reusable domain logic under `packages/`

Suggested package split:

- `core-models`
- `provider-kit`
- `memory-engine`
- `design-system`
- `sync-kit`

## Why This Stack

### `SwiftUI`

Best fit for an iPhone-first product where design quality and platform feel matter early.

Reasons:

- fastest path to polished native interaction
- clean support for dynamic type, accessibility, and Apple platform conventions
- easier path to future widgets and system-facing surfaces

### `Observation`

Good default for modern SwiftUI state handling.

Reasons:

- lightweight and native
- avoids bringing in extra app architecture dependencies too early
- works well for a small team and a still-forming product

### `SwiftData`

Good v1 choice for the local working store, as long as we keep the storage boundary clean.

Reasons:

- native persistence model for Swift apps
- good fit for scopes, memories, categories, and retrieval records
- lowers setup cost for an early product

Important note:
This is a pragmatic v1 choice, not an irreversible bet. The domain layer should not depend directly on storage details everywhere. If the product later needs a more explicit database layer or sync architecture, we should be able to swap the persistence implementation behind repository boundaries.

### `CloudKit`

Recommended as the first cloud-backed durability path for Apple-platform users, planned as a `v1.5` fast follow rather than a `v1` requirement.

Reasons:

- Apple positions it as the native way to sync app data across a person's devices
- the user's private database is owned by that user and counts toward their iCloud storage
- it gives us a strong path to near-zero-friction migration across Apple devices

Important note:
CloudKit should be treated as a user-controlled durability and sync layer, not a required hosted service. The app should still be able to function without it.

### `URLSession`

Default networking layer for provider APIs.

Reasons:

- native and stable
- enough for straightforward JSON request/response work
- no need for third-party networking abstractions in v1

### `Keychain`

Required for BYO API keys.

Reasons:

- aligns with the personal-first security posture
- avoids inventing our own secrets handling
- works cleanly with future extension sharing if needed

## Testing

Recommended split:

- `Swift Testing` for new unit tests
- `XCTest` for UI tests and any remaining integration needs

This gives us a modern default for new code while staying aligned with Apple’s established UI testing path.

## Future-Ready Platform Features

Not required for the first implementation, but the stack should leave room for:

- share sheet capture via app extensions
- shared storage between app and extension via App Groups
- Shortcuts and Siri entry points via App Intents
- glanceable scope surfaces via WidgetKit
- CloudKit-backed sync for structured user data
- export/import for portable ownership

These are part of why native iOS remains the better v1 path for this product.

## What To Avoid In V1

- React Native or Expo as the primary client stack
- heavy third-party architecture frameworks
- cloud-required auth or sync for basic use
- a large backend before the app proves its personal-use loop
- plugin systems

## Working Principles

1. Prefer first-party Apple frameworks where they are good enough
2. Keep domain logic portable and testable
3. Keep persistence and provider code behind clean boundaries
4. Build the default experience first, then expose deeper controls
5. Preserve a clean path to app extensions, sync, and system integrations

## Open Questions

- whether `SwiftData` remains sufficient after the first real memory and retrieval prototypes
- whether asset sync should use CloudKit-backed records, document-based iCloud storage, or staged export/import first
- whether the first release supports one provider or two
- whether the design system should live as a separate package immediately or after the first prototype
