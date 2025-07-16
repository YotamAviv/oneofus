# Discussion
## Challenges
- I haven't successfully run the Firebase emulator with an actual phone (with a camera) (I probably just need to change a local host setting somewhere).
- Copy/paste is funky between emulator / Linux / emacs.
- Firebase seems to cache on the phone.

## 2 phones not required
- I own my own Android but don't want to mess with it.
- I own a designated testing phone (Moto G Play) for this.
- The Android Emulator phone is fine for much but can't be used to scan QR codes, and it can't open website links, 
  which do need to be tested.

## Firestore: Production or Fake
Using prod is required for some stuff. Easiest to just use it across the board.

## Nerdster bugs
Do note these.
Email me or submit at: https://github.com/YotamAviv/nerdster/issues

# Test Plan

- Wipe app data on Android (or use the Dev menu if compiled in Dev mode)
  - Create new key

- QR web sign-in using phone scanner, without creating a delegate key
  - create delegate: NO
  - Verify
    - Phone: Use menu /etc => Import/Export, verify that you only see the one-of-us.net key.
    - Nerdster on Web: centered (not centered as Yotam) but not with delegate. On the Nerdster, turn on menu => Settings => everything. In the tree view, verify that "Me" has no children. Scan QR with phone to verify.

- QR web sign-in again, create delegate
  - create delegate: YES
  - Refresh Nerdster after QR sign-in
  - Verify
    - Phone: Use menu /etc => Import/Export, verify that you see both the one-of-us.net key and a nerdster.org key.
    - Web: centered and signed in. On the Nerdster, turn on menu => Settings +> everything. In the tree view, verify that "Me" has a delegate key and a a delegate statement.  Scan QR with phone to verify.

- Submit 2 things, verify revokeAt 
  - submit (and recommend) subject "A"
  - submit (and recommend) subject "B"
  - revoke delegate at first (the earlier of the 2, "A")
  - refresh Nerdster and check. You should see A but not B.
    - (Nerdster should display revoked key cross out like on the phone.)
  - TODO: Don't allow submitting with revoked key. Looks like I'm halfway there - an assertion fires.
  - revoke at "since always" and check. You should see neither A nor B.
  - un-revoke. You should see both A and B again.

- Trust a stranger, use Amotz
  - Scan QR from the https://nerdster.web.app (or use local Nerdster on emulator copy)
    - (Trusting from both the main screen or the trusts screen should be tested, maybe test a different one each time.)
    - Exit app and restart.
    - Trust Amotz again. App should should show existing trust
      - edit trust
      - block
      - clear

- Claim an existing key, use Yotam's
  - Use menu State => {replace}
  - Scan Yotam's key from https://nerdster.web.app/?showJson=true&showStatements=true&showKeys=true&skipVerify=true
  - Verify that you see options related to last statement token
  - Trust yourself and fail gracefully (Use a trust method to trust these below)
    - Yotam
    - Yotam's delegate
    - Yourself (You'll need to QR sign into the Nerdster to see your own QR code)
  - Verify: The app should show Yotam's not-local delegate key uner menu State => {delegate}

- Claim a delegate
  - fail gracefully on these below:
    - your own Oneofus key.
    - your own delegate key.
    - equivalent Oneofus key, use Yotam's
    - one of your existing delegate keys, use Yotam's
  - Claiming Andrew's delegate key (complicated...)
    - type in "nerdster.org", yes, overwrite my key. 
      TODO: BUG: Warns that I'll be overwriting a key.
    - refresh the Nerdster and check it out if you want to test the Nerd'ster:
      - Andrew should no longer have a delegate key 
      - Clear my reaction completely works as expected regardless (impressive in cases where Yotam and Andrew rated)

- Start again (wipe) (probably not necessary, can probably optimize)

- Claim Yotam's key from the start
  - Replace Yotam's key revoking a few statements back

- QR sign in
  - App should offer to create delegate key, YES
  - Verify Nerdster seems okay with me using Yotam's Oneofus key.. Just submit something.

- Replace my key (State menu => {replace})
  - Replace my key
    - re-state trust in Amotz with the new replacement key
  
- Check all hyperlinks
  - menu => ?
    - Keys
    - Statements
    - About
  - confirmations and warnings contain links, too. In case I missed any, please point them out.
    - block warning
    - claim existing key warning
    - replace my key warning

- Rotate phone, d'oh!

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

