# Technical Design: V2 Data Layer

This document outlines the proposed architecture for the `oneofus` mobile app's data layer, a strategy for sharing code with the `nerdster` project, and a plan for testing.

## From the human
- check out the oneofus project minus .git and truly start from scratch?
- get started on the "magic" connecting domain to app as that takes time.

## 1. Problem Statement

The current data-fetching logic (`Fetcher`) is complex and difficult to maintain. The `nerdster` project contains a more modern "v2" data layer, but simply copying this code is undesirable and leads to maintenance issues. The `oneofus` app also has different requirements than `nerdster`; it is primarily a writer of its own statements and does not need to read statements from many users in parallel.

## 2. Proposed Architecture

We will create a new, well-defined I/O layer within the `oneofus` project. This layer will be inspired by `nerdster`'s v2 architecture but tailored to the specific needs of the phone app.

### 2.1. Components

-   **`lib/v2/statement_io.dart`**: An abstract interface defining the contracts for reading and writing statements.

    ```dart
    abstract class StatementSource<T extends Statement> {
      Future<Map<String, List<T>>> fetch(Map<String, String?> keys);
    }

    abstract class StatementPusher {
      Future<void> push(Statement statement);
    }
    ```

-   **`lib/v2/direct_firestore_source.dart`**: A concrete implementation of `StatementSource` and `StatementPusher`. This will be the **primary I/O component for the phone app**. It will read from and write directly to Firestore.

-   **`lib/v2/notary_chain_verifier.dart`**: A dedicated, testable class responsible for verifying the integrity of a fetched list of statements. It will check the `previous` token links and timestamps. This logic will be explicitly invoked by `DirectFirestoreSource` after a fetch.

-   **`lib/v2/source_factory.dart`**: A factory responsible for providing instances of the data sources. Initially, it will only create `DirectFirestoreSource`.

## 3. Code Sharing Strategy

To avoid code duplication, we should move the core, shared logic into a common package. The `nerdster` and `oneofus` projects would then both depend on this package.

**Proposed Shared Package: `oneofus_common`**

This new Flutter package would contain:
-   **Core Data Models:** `statement.dart`, `trust_statement.dart`, `jsonish.dart`, etc.
-   **Cryptography:** The `crypto` directory and its contents.
-   **Paradigm Constants:** `util.dart` (containing `kOneofusDomain`, etc.).

This approach ensures that the fundamental data structures and cryptographic logic are identical and maintained in a single place.

## 4. Testing Strategy

-   **Unit Tests:**
    -   A dedicated unit test file for `notary_chain_verifier_test.dart` must be created. It should be tested with valid chains, broken chains, and chains with timestamp violations.
    -   `direct_firestore_source_test.dart` will use `FakeFirebaseFirestore` and will test that the source correctly fetches data and correctly invokes the `NotaryChainVerifier`.

-   **Integration Tests (`integration_test/app_test.dart`):**
    -   These tests will continue to use `FakeFirebaseFirestore` populated with the `simpsons_demo` data.
    -   They will simulate user UI interactions (tapping, scrolling) and verify that the UI correctly reflects the state from the fake database. This validates the entire stack, from UI to the I/O layer.

## 5. Open Questions

1.  **Shared Package Location:** Should the `oneofus_common` package be a local package within a monorepo, or should it be published as a private package?
2.  **`DirectFirestoreSource` vs. `CloudFunctionsSource`:** The phone app's primary need is direct I/O. Is there any scenario where it would need to use the `CloudFunctionsSource` for reading? If not, we can omit it from the phone app's architecture entirely for simplicity.
3.  **Migration Path:** How do we handle the transition from the legacy `MyKeys` and `MyStatements` classes to the new v2 I/O layer? Should the v2 layer be responsible for migrating the secure storage data, or should that be a separate, one-time process?
