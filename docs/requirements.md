# Phone App Requirements

This document outlines the high-level requirements for the ONE-OF-US.NET mobile app.

## Introduction

This document specifies the functional and non-functional requirements for the ONE-OF-US.NET mobile app. It details the core features, use cases, and security considerations that guide the app's design and development.

## 1. Core Requirements

### 1.1. Build the Identity Network

The app must allow users to build the web of trust by issuing `trust` statements.

**Use Case: Vouching for another user (`trust`)**

1.  The user must be able to initiate a scan of another user's public Identity Key QR code.
2.  The app must allow the user to enter a `moniker` for the subject.
3.  Upon confirmation, the app must sign and publish a `trust` statement.

### 1.2. Manage Statements and Keys

The app must provide a comprehensive interface for managing existing statements and keys.

**Use Case: Editing a Statement**

1.  The user must be able to select any statement they have previously made.
2.  The app must allow the user to edit fields like `moniker` or `comment`.
3.  Upon confirmation, the app must sign and publish a new statement for the same subject, which should be interpreted as overriding the previous one.

**Use Case: Blocking a Bad Actor (`block`)**

1.  The user must be able to block an identity by scanning their QR code, pasting their public key, or selecting an identity from their existing statements.
2.  Upon confirmation, the app must sign and publish a `block` statement for that identity.

**Use Case: Clearing a Statement (`clear`)**

1.  The user must be able to select any statement they have previously made.
2.  The app must allow the user to issue a `clear` statement for that subject. This new statement should be interpreted by consumers as nullifying any previous disposition.

**Use Case: Replacing a Lost or Compromised Identity Key (`replace`)**

1.  The user must be able to initiate the key replacement process.
2.  The app must generate a new Identity Key Pair.
3.  The app must require the user to provide the public key of the old key being replaced.
4.  The app must require a `revokeAt` token. This token identifies the last statement that should be considered valid. Statements made by the old key after this token should be considered invalid. If the token does not match any past statement (e.g., using the convention `<since always>`), the old key should be considered entirely and retroactively revoked.
5.  Upon confirmation, the app must sign the `replace` statement with the *new* identity key and publish it.

**Use Case: Revoking a Delegate Key**

1.  The user must be able to select a `delegate` statement they have previously made.
2.  The app must allow the user to issue a new `delegate` statement for the same `domain`, including a `revokeAt` token.
3.  The `revokeAt` token signals that consumers should consider statements made by the delegate key after the specified token as invalid.

### 1.3. Delegate to Services

The app must allow users to delegate authority to third-party services.

**Use Case: Initial Delegate Sign-in (via QR Code)**

1.  The user must be able to initiate a scan of a service's Sign-in Parameters QR code.
2.  If no Delegate Key exists for the service's domain, the app must ask for user consent to create one.
3.  Upon consent, the app must publish a `delegate` statement linking the new Delegate Key to the user's Identity Key.
4.  The app must transmit the user's public Identity Key and the service-specific Delegate Key Pair to the service via HTTP POST.

**Use Case: Seamless Delegate Sign-in (vNext)**

1.  A user on a third-party website (e.g., `nerdster.org`) must be able to click a sign-in link.
2.  This link must automatically open the ONE-OF-US.NET phone app.
3.  The app must handle the delegation flow as described in the QR code use case, returning the user to the website upon completion.

### 1.4. Share Identity

The app must allow users to share their identity for remote vouching.

**Use Case: Sharing Public Key**

1.  The user must be able to select a 'Share' option for their own identity.
2.  The app must provide options to share the public Identity Key as a QR code image or as text (JSON format).
3.  The app must use the native platform sharing functionality (e.g., email, text, etc.).

**Security Considerations**

The paradigm relies on the social judgment of its users. The app does not and cannot enforce that vouching occurs in person. A user may choose to trust another user by scanning a key from a screenshot or email. This is an inherent security trade-off; the strength of the network relies on users making good-faith judgments about who they trust and how they verify identity.

### 1.5. Key Portability

The app must allow users to export and import their keys to ensure they own their identity and are not locked into the app.

**Use Case: Exporting Keys**

1.  The user must be able to initiate an export of all their keys.
2.  The app must provide the user with a portable and secure format for their Identity and Delegate Key Pairs.
3.  The app must allow the user to copy this data to the clipboard or share it.

**Use Case: Importing Keys**

1.  The user must be able to initiate an import of keys.
2.  The app must provide a way to paste the key data.
3.  The app must validate the imported keys.
4.  Upon successful validation and confirmation, the imported keys must replace all existing keys within the app.
