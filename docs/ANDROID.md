# Android builds and Samsung Galaxy S20+ installation

Reelworks Arcade uses **Godot 4.7.2 stable** and the matching **4.7.2.stable export templates**. It runs offline with OpenGL compatibility rendering, portrait orientation and ARM64 code. The Galaxy S20+ running Android 13 is an intended target; device performance and lifecycle testing must still be performed on a physical handset. The debug APK is a private testing build, not a store release.

## Automated private build

1. Put this repository in a **private GitHub repository**. No remote repository is created by the build scripts.
2. Open **Actions → Private Android debug build → Run workflow**. It also runs for main/master pushes and pull requests.
3. The workflow installs the exact editor and templates, Java 17 and Android SDK tools, imports resources, rejects script errors, runs gameplay tests and the deterministic simulation, then exports a signed debug APK.
4. Download the **ReelworksArcade-debug** workflow artifact. It contains `ReelworksArcade-debug.apk`, its SHA-256 checksum and test/simulation logs. Artifacts expire after seven days and require repository access.

The job explicitly refuses to run in a public repository. It does not publish releases, deploy to a store, or require signing secrets. Every build generates a temporary development key outside the repository and deletes it after export. **A different build has a different signing identity**, so Android may require uninstalling the previous build first; uninstalling removes local saved progress. A stable private development keystore can be used manually in the Godot editor if preserving installs across builds is desired. Never commit it.

## Local Linux build

Install Python 3, a Java 17 JDK and Android command-line tools. Use `sdkmanager` to accept the Android SDK licenses and install:

```sh
sdkmanager --licenses
sdkmanager 'platform-tools' 'platforms;android-36' 'build-tools;36.0.0'
python3 tools/install_godot.py --directory "$HOME/.local/bin"
```

Set `JAVA_HOME` to the JDK directory and `ANDROID_HOME` to the Android SDK directory. The installer uses the official Godot release and verifies asset sizes and available published SHA-256 digests. It installs only Android export templates from the matching archive; no third-party export-template build is used.

```sh
export GODOT_BIN="$HOME/.local/bin/godot"
"$GODOT_BIN" --headless --path . --editor --import --quit
"$GODOT_BIN" --headless --path . --script res://tests/test_runner.gd
"$GODOT_BIN" --headless --path . --script res://tests/simulation.gd
bash tools/export_android.sh
```

The result is `builds/ReelworksArcade-debug.apk`. The script rejects the wrong Godot version, creates isolated editor settings and temporary signing credentials, verifies the APK signature and checks 16 KB alignment. Release credentials are never needed. The preset targets `org.reelworks.arcade` and contains no internet permission; vibration permission supports the optional haptic setting.

## Install on the Galaxy S20+

- Transfer `ReelworksArcade-debug.apk` to the phone, open it in **My Files**, and allow **Install unknown apps** for that app when Android asks. Install and launch **Reelworks Arcade**. Revoke that install permission afterward if desired.
- Alternatively, enable Developer options by tapping **Settings → About phone → Software information → Build number** seven times, turn on USB debugging, connect the phone and accept its debugging prompt, then run:

```sh
adb devices
adb install -r builds/ReelworksArcade-debug.apk
```

If Android reports `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, the existing build was signed with a different temporary key. Uninstall the old build in Android settings and install again. This clears the old local save. No account, connection or payment is required to play.

On the handset, check all three cabinets, readable portrait layout, feature-board zoom, hold/nudge/hi-lo input, mute/haptics, Back navigation and interruption during spinning and bonus awards. Rotate the handset to confirm portrait remains locked. Background and resume the app and reopen it after force-stop to check progress. Test reduced-motion and reduced-flashing modes. Keep airplane mode enabled for an offline check. Report actual handset observations separately from headless test results.

## Later Google Play AAB preparation (not performed)

1. Complete `docs/PUBLICATION_CHECKLIST.md`, including rights, audience/content rating and applicable simulated-gambling policies. No store-readiness claim is made by this development build.
2. Choose a permanent application ID and increment version code for each upload. Review the then-current Play target SDK and 16 KB page-size requirements.
3. Install the matching Godot Android build template from **Project → Install Android Build Template**. Enable **Gradle Build** on a separate Android release preset, set its export format to **AAB**, and include ARM64. Use a supported JDK and the SDK/NDK versions documented by that Godot release.
4. Generate and securely back up a dedicated **upload key** outside the repository. Configure Play App Signing and keep the upload password and key in secure secrets. Set `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER` and `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` in the private release environment; do not put their values in `export_presets.cfg`.
5. Export with `godot --headless --path . --export-release "Android Release" builds/ReelworksArcade.aab`, inspect the bundle with Android's bundletool, and test device-specific APKs. The `Android Release` preset is intentionally not preconfigured with credentials; create and review it when preparing a real release.
6. Upload only after explicit publication authorization. This project and workflow do not upload to Google Play.
