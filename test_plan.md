## Testing challenges
- I haven't successfully run the Firebase emulator with an actual phone (with a camera) (I probably just need to change a local host setting somewhere).
- Copy/paste funky between emulator / Linux / emacs inconsistent behavior.
- Firebase seems to cache on the phone.

### 2 phones?
- I own my own Android but don't want to mess with it.
- I own a designated Moto G Play for this.
- The Android Emulator ('3a') is fine for much but can't scan anything (can't point camera at it), and it can't open website links, 
  which do need to be tested.

### PROD. Fake, too
Using prod is required for some stuff

## Test Plan

- Prod
  - MotoG
      - wipe
      - create new key
      - QR web sign-in using phone scanner
          - create delegate, no
          - verify
            - Phone: Export
            - Web: centered but not with delegate
  - Moto
    - QR web sign-in again
      - create delegate yes
      - check:
        - Web: submit and verify
        - Phone: Export

- submit 2 things
  - revoke delegate at 1'st
    - refresh Nerdster and check
  - revoke at always.
  - un-revoke

- trust a stranger, use Amotz
  - (QR code or copy/paste), (main screen or trusts screen)
  - restart app, trust Amotz again using person_add, should show existing trust
    - edit trust
    - block
    - clear

- claim a used key, use Yotam's
    - (3a okay or Moto, okay, still PROD)
    - verify see options for last statement token
  - trust yourself and fail  gracefully
    - Yotam
    - Yotam's delegate
    - yourself
  - Verify: should show Yotam's not-local delegate key

- claim a delegate
  - fail gracefully on equiv key, use Yotam's
  - fail gracefully on existing delegate key, use Yotam's delegate
  - fail gracefully on my own Oneofus key.

- started again (wipe), probably not necessary, can probably optimize

- claim Yotam's from the start
  - replace Yotam's key revoking a few statements back
- sign in
  - should offer to create delegate key

- replace my key
  - replace my key
    - re-state trust in Amotz with my key

## List of functionality to test
- Clean start
- QR Sign in
- New trust
- Equivalent keys display correctly
- Delegates display correctly
- Modify trust
- Modify revokeAt Oneofus equivalents
- Revoke/modify revokeAt delegate
- Can't modify delegate domain
- Import/Export
- Claim lost key
- Replace key
- Claim delegate
- Create delegate key

