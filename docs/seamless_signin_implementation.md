# Seamless Sign-In Implementation Guide
## Deep Linking for ONE-OF-US.NET and Nerdster

This document outlines the steps to replace the QR code/Copy-Paste sign-in flow with a seamless "One-Tap" deep linking experience.

### 1. Overview
The goal is to allow the Nerdster web app to trigger the ONE-OF-US.NET mobile app directly.
- **Web Trigger:** A link like `https://one-of-us.net/sign-in?data=...`
- **Mobile Action:** The OS recognizes the link, opens the ONE-OF-US.NET app, and passes the `data` parameter to the existing sign-in logic.

---

### 2. Android Setup (App Links)
Android App Links allow your app to designate itself as the default handler for a domain.

#### A. Create `assetlinks.json`
Create a file at `https://one-of-us.net/.well-known/assetlinks.json`:
```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "net.one_of_us.app", 
      "sha256_cert_fingerprints": [
        "YOUR_APP_SHA256_FINGERPRINT"
      ]
    }
  }
]
```
*Note: Get your SHA256 via `./gradlew signingReport` in the Android folder.*

#### B. Update `AndroidManifest.xml`
Add this intent filter to your `.MainActivity` in `android/app/src/main/AndroidManifest.xml`:
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="one-of-us.net" android:pathPrefix="/sign-in" />
</intent-filter>
```

---

### 3. iOS Setup (Universal Links)
Universal Links are the iOS equivalent, requiring a verified handshake.

#### A. Create `apple-app-site-association` (AASA)
Create a file (no extension) at `https://one-of-us.net/.well-known/apple-app-site-association`:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "YOUR_TEAM_ID.net.one-of-us.app",
        "paths": ["/sign-in*"]
      }
    ]
  }
}
```
*Note: The server must serve this with `Content-Type: application/json`.*

#### B. Xcode Configuration
1. Open the project in Xcode on your Mac.
2. Go to **Signing & Capabilities**.
3. Add the **Associated Domains** capability.
4. Add an entry: `applinks:one-of-us.net`.

---

### 4. Flutter Implementation
Use the `app_links` package to handle the incoming stream of URLs.

#### A. Add Dependency
```yaml
dependencies:
  app_links: ^6.0.0
```

#### B. Handle Incoming Links
In your `main.dart` or a dedicated service:
```dart
import 'package:app_links/app_links.dart';

final _appLinks = AppLinks();

void initDeepLinks() {
  // Handle links when app is already running
  _appLinks.uriLinkStream.listen((uri) {
    _handleSignIn(uri);
  });

  // Handle link that launched the app
  _appLinks.getInitialAppLink().then((uri) {
    if (uri != null) _handleSignIn(uri);
  });
}

void _handleSignIn(Uri uri) {
  if (uri.path == '/sign-in') {
    final data = uri.queryParameters['data'];
    if (data != null) {
      // Trigger your existing HTTP POST logic here
      print('Received sign-in data: $data');
    }
  }
}
```

---

### 5. Testing Strategy
1. **Android:** Use ADB to simulate a link:
   `adb shell am start -a android.intent.action.VIEW -d "https://one-of-us.net/sign-in?data=test" net.one_of_us.app`
2. **iOS:** Paste the link into the Notes app and long-press it. It should show "Open in ONE-OF-US.NET".
3. **Web:** Update the Nerdster "Sign In" button to check if the user is on mobile and provide the HTTPS link instead of the QR code.

---

### 6. Security Considerations
- **Validation:** Always validate the `data` payload inside the app before performing the POST.
- **HTTPS Only:** Never use custom schemes (like `oneofus://`) for sensitive data, as they can be hijacked by other apps. Universal/App Links are tied to your domain and are secure.
