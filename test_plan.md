## Testing challenges
- I haven't successfully run the Firebase emulator with an actual phone (with a camera) (I probably just need to change a local host setting somewhere).
- Copy/paste is funky between emulator / Linux / emacs.
- Firebase seems to cache on the phone.

### 2 phones?
- I own my own Android but don't want to mess with it.
- I own a designated testing phone (Moto G Play) for this.
- The Android Emulator phone is fine for much but can't scan QR codes, and it can't open website links, 
  which do need to be tested.

### PROD. Fake, too
Using prod is required for some stuff

## Test Plan

- Start
    - wipe
    - create new key
  - QR web sign-in using phone scanner, without creating a delegate key
    - create delegate: NO
    - verify
      - Phone: Use menu /etc => Import / export private keys => Export, verify that you only see the one-of-us.net key.
      - Web: centered (not centered as Yotam) but not with delegate. On the Nerdster, turn on menu => Prefs +> everything. In the tree view, verify that "Me" has no children. 
  - QR web sign-in again, create delegate
    - create delegate yes
    - verify
      - Phone: Use menu /etc => Import / export private keys => Export, verify that you only see the one-of-us.net key.
      - Web: centered and signed in. On the Nerdster, turn on menu => Prefs +> everything. In the tree view, verify that "Me" has a delegate key and a a delegate statement.

- Submit 2 things, verify revokeAt 
  - submit subject "A"
  - submit subject "B"
  - revoke delegate at 1'st (the earlier of the 2, "A")
    - 
      - refresh Nerdster and check. You should A but not B.
      - revoke at always.
      - un-revoke

- trust a stranger, use Amotz
  - (QR code or copy/paste), (main screen or trusts screen)
  - restart app, trust Amotz again using person_add, should show existing trust
    - edit trust
    - block
    - clear

- claim an existing key, use Yotam's
    - (3a okay or Moto, okay, still PROD)
    - verify see options for last statement token
  - trust yourself and fail gracefully
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

