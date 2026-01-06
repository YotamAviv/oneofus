# Core Specification

## 1. Introduction: A Decentralized Web of Trust

This document specifies the `one-of-us.net` paradigm, a decentralized identity system based on a web of trust. The ONE-OF-US.NET mobile app is the reference implementation for this paradigm.

The core of the paradigm is the **Statement**: a signed, portable JSON object. Trust in a statement comes from its cryptographic signature, not from the service that hosts it. These statements can be published anywhere on the web and aggregated by any service.

## 2. Core Function: Building the Identity Network

The primary purpose of the ONE-OF-US.NET phone app is to build the web of trust by allowing users to vouch for one another.

### The Vouching Process

1.  **Display:** A user (the "subject") displays a QR code of their public **Identity Key** on their phone screen.
2.  **Scan:** Another user (the "issuer") uses their ONE-OF-US.NET app to scan the subject's QR code.
3.  **Vouch:** The issuer's app prompts them to vouch that the subject is "human, capable, and acting in good faith" and to provide a `moniker` (a name, like "Maggie").
4.  **Sign & Publish:** Upon confirmation, the issuer's app signs a `trust` statement and publishes it to a public cloud service (e.g., Firebase). This statement can then be discovered by any service that knows the issuer's public key or its token.

Here is an example of the resulting `trust` statement:

```json
{
  "statement": "net.one-of-us",
  "time": "2024-05-25T04:00:00.000Z",
  "I": {
    "crv": "Ed25519",
    "kty": "OKP",
    "x": "NOqGmF9lMMWEUL9lMWs0mZZM9BSybVplqvawUkLbwOs"
  },
  "trust": {
    "crv": "Ed25519",
    "kty": "OKP",
    "x": "tiEji6yuP5Sp0CyiJylIPa24WnkajnRI0tB_XmiSmd4"
  },
  "with": {
    "moniker": "Maggie"
  },
  "previous": "2f5a4cf8cf8de8595af284b60cc816194a71790b",
  "signature": "0067dd21bc3cfa75e44e996445bcb70bee21b016d6a45b02fe8d9b44ccec70d416f284540631ef1121d3a511cc1e1c3ffce734cfb8096913bfdb42313f42e203"
}
```
A service like Nerdster might interpret and display this statement in a more human-readable format:

```json
{
  "time": "5/24/2024 12:00 AM",
  "I": "Lisa",
  "trust": "Mom",
  "with": {
    "moniker": "Mom"
  }
}
```

### Phone App vs. The Network

The ONE-OF-US.NET phone app does not compute the identity network. It only builds specific edges (or in the case of blocks, non-edges) in a cryptographically trusted way. It is up to other services, like Nerdster, or "the Internet" to aggregate these statements and compute the graph. This is a complex problem that is expected to evolve.

## 3. Statement Verbs

The paradigm defines five core verbs that can be used in statements:

-   **`trust`**: An assertion that the subject is a real human acting in good faith. This is the primary mechanism for building the identity network.
-   **`block`**: An assertion that the subject is a bad actor (e.g., a bot or spammer). This effectively creates a "non-edge" in the graph for the issuer.
-   **`replace`**: Allows a user to transition their identity to a new key if their old key is lost or compromised. This statement is important for maintaining continuity in the network.
-   **`delegate`**: Links a user's Identity Key to a service-specific Delegate Key, allowing them to interact with third-party services.
-   **`clear`**: Acts as an eraser, revoking any previous statement the issuer has made about a specific subject.

## 4. Secondary Function: Delegating to Services

After establishing their identity within the trust network, users can delegate authority to third-party services.

### The Delegate Sign-in Flow

1.  A third-party service (e.g., a website like `nerdster.org`) displays a QR code containing **Sign-in Parameters**. This tells the phone app where to transmit the user's identity information.
2.  The user scans this QR code with their ONE-OF-US.NET app.
3.  The app checks for a stored Delegate Key Pair for the service's domain. If one does not exist, with the user's consent, the app generates a new key pair and publishes a `delegate` statement. This statement, signed by the user's Identity Key, creates a public, verifiable link proving that the new Delegate Key represents the user on that specific service.
4.  The app transmits the user's public **Identity Key** and the service-specific **Delegate Key Pair** to the service via an HTTP POST request.
5.  The service now possesses a Delegate Key that is publicly and verifiably linked to the user's identity. This enables cross-service identity verification.

### The Power of Delegation

Any service or user can now recognize that content signed by this delegate key truly represents the original person. For example, an observer like Lisa can cryptographically verify that content from `Bart@nerdster.org` and `Bart@discord.com` comes from the same person, because both delegate keys are publicly linked back to Bart's single, trusted Identity Key.

## 5. Technical Specification

### 5.1. Data Structures

- **Keys:** Users control **Identity Keys** (long-term) and issue **Delegate
  Keys** (service-specific) via `delegate` statements. Keys are represented as
  JSON Web Keys (JWK).

- **Statements:** Statements are JSON objects with the following general structure:

  ```json
  {
    "statement": "net.one-of-us",
    "time": "<ISO-8601 Timestamp>",
    "I": <Identity Public Key JSON>,
    "<verb>": <Subject Public Key JSON>,
    "with": {
       "moniker": "...",
       "revokeAt": "...",
       "domain": "..."
    },
    "comment": "...",
    "previous": "<Token of previous statement>",
    "signature": "<Crypto Signature>"
  }
  ```
  - **`<verb>`**: The action: `trust`, `block`, `replace`, or `delegate`.
  - **`with`**: Optional metadata. `domain` is required for `delegate`
    statements. `revokeAt` is required for `replace` statements and optional
    for `delegate` statements.

### 5.2. The Token

A **Token** is a SHA-1 hash of the canonical JSON representation of an object (Key, Statement, etc.).

> **Note:** The canonicalization rules and hashing algorithm (SHA-1) are fundamental to the paradigm's integrity and should not be changed.

### 5.3. Canonicalization and Signing

To ensure consistent hashing and verifiable signatures, JSON objects are strictly ordered before being converted to a string for signing.

### 5.4. The Notary Chain

Every statement contains a cryptographic link (`previous` field) to the preceding statement from the same issuer. This creates a tamper-evident history that consumers of the data should verify. If a gap or mismatch is found in the chain, the consumer should consider the entire chain corrupt.

### 5.5. Singular Disposition

The paradigm provides a "Latest-Write-Wins" model. A newer statement (e.g., `block`) should be interpreted by consumers as overriding an older one (e.g., `trust`) for the same `Issuer:Subject` pair. The `clear` verb signals that any prior disposition should be considered nullified.

### 5.6. Storage & Sync Requirements

The storage layer must support efficient querying of statements, sharded by **Issuer** and indexed by **Time**.
