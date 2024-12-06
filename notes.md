# Nice ones:
git tag PROD-v`date2`




2008  history
 2009  firebase login
 2010  dart pub global activate flutterfire_cli
 2011  flutterfire configure
 2012  flutter pub add firebase_core
 2013  flutterfire configure
 




# BUGS:

- Andrew bug (fixed)
  - don't see that I already trust Andrew when I person_add.
  - see clear twice when I try and re-trust Andrew (or anyone), but not always.
    Before displaying my trust/blocks, I don't see trust twice.


- Huh? delegate confusion after importing keys

# TODO:


# Testing..
- automated test for some of the functions
  - getEquiv... returns mine too, maybe test, definitely doc and/or rename
  - simulate MyKeys (secure storage)

## Doc:
- manual
  - explain lost, yours, equiv...
    - lost key: can't clear (erase) or overwrite equivalent statements 

** delegates **
  - DEFER:
    - when replacing key, offer to claim delegate keys
    - when clearing a delegate key, warn that you'll lose the delegate keys stored on your phone and then delete them.
    - Improve revoke delegate revokeAt  
      - Can say: 'Picking the delegate statement is outside the scope of this app. Find the statement on the other app; we'll try and verify that this key stated it.'
      - try and verify that this key made it.
    - minor (and not so nerdy)
      - enforce lower case domain? (nerdster.org, not Nerdster.org)


# Firestore functions
copied functions dir from Nerdster
ran npm install in functions directory
copied functions section in firebase.json from Nerdster, too
firebase deploy --only functions
Deployed! Try at: https://us-central1-one-of-us-net.cloudfunctions.net/export?token=2c3142d16cac3c5aeb6d7d40a4ca6beb7bd92431

# History
## 6/17/24
added icon as per https://dev.to/vtsen/step-by-step-guides-to-add-android-app-icon-596l
Closed the 'oneofus2' project and Opened the 'android' project as per https://stackoverflow.com/questions/70816347/i-cant-find-the-image-asset-option-in-android-studio
Something lead to a huge update, or even several, gradle, yada, yada..
Made 2 changes:
- one per advice in the output window that lead to:
```
diff --git a/android/app/build.gradle b/android/app/build.gradle
-    ndkVersion = flutter.ndkVersion
+    ndkVersion "26.1.10909125"
```
- one per: https://stackoverflow.com/questions/75480173/android-studio-build-error-compiledebugjavawithjavac-task-current-target-is-1
