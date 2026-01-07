# Session Summary

## Goal

The primary goal is to rewrite the `oneofus` mobile app to improve its user interface and architecture, while maintaining compatibility with the existing data and "legacy" app versions. The new version should be more user-friendly and easier to maintain.

## Key Documents

We have created two main documents to guide this effort:

1.  **`docs/core_specification.md`**: Describes the `one-of-us.net` paradigm, including the core concepts of statements, keys, and the identity/delegate networks.
2.  **`docs/requirements.md`**: Outlines the functional requirements for the mobile app, detailing use cases for building the network, managing statements, delegating to services, and key portability.

## Architectural Direction

-   **UI Rewrite:** We will replace the old, complex UI with a new, simpler interface based on a `BottomNavigationBar` and a central `FloatingActionButton`.
-   **Data Layer Rewrite:** We will replace the legacy `Fetcher` class with a new v2 data layer inspired by the `nerdster` project. This will be centered around a `StatementSource` interface with a `DirectFirestoreSource` implementation.
-   **Code Sharing:** We plan to create a common package (`oneofus_common`) to share core logic (data models, cryptography) between the `oneofus` and `nerdster` projects to avoid code duplication.
-   **Testing:** A major focus is on building a robust testing suite. We will use `integration_test` with `FakeFirebaseFirestore` and the `simpsons_demo` data to create UI-level tests that validate the app's behavior against a known state.

## Current Status

-   The documentation (`core_specification.md` and `requirements.md`) is in a good state, capturing the core concepts and requirements.
-   We have created a `technical_design.md` document that outlines the proposed architecture for the v2 data layer, a code-sharing strategy, and a testing plan.

## Next Steps

The immediate next step is to begin implementing the technical design. This involves:
1.  Creating the `oneofus_common` package (or deciding on an alternative code-sharing strategy).
2.  Implementing the v2 data layer components (`StatementSource`, `DirectFirestoreSource`, `NotaryChainVerifier`).
3.  Building out the integration tests using the `simpsons_demo` data.
4.  Connecting the new v2 UI to the new v2 data layer.

## Session Notes
- A reference copy of the `nerdster` project exists locally at `nerdster-reference` to provide context and code for the v2 rewrite.
- **Priority Task for Next Session:** Create the `oneofus_common` package to begin the code-sharing strategy.
