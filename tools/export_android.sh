#!/usr/bin/env bash
# Signed ARM64 debug APK. All signing material lives in a temporary directory.
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
android_sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [[ -z "$android_sdk" || ! -d "$android_sdk/build-tools" ]]; then
  echo 'Set ANDROID_HOME to an SDK with platform-tools and build-tools 36.0.0.' >&2
  exit 1
fi
if [[ "$($godot_bin --version)" != 4.7.2.stable.* ]]; then
  echo 'Reelworks Arcade requires Godot 4.7.2 stable and matching templates.' >&2
  exit 1
fi
if [[ -z "${JAVA_HOME:-}" ]] && ! command -v javac >/dev/null; then
  echo 'Install a JDK (Java 17 recommended) and set JAVA_HOME; a JRE alone is insufficient.' >&2
  exit 1
fi
java_sdk="${JAVA_HOME:-$(dirname -- "$(dirname -- "$(readlink -f -- "$(command -v javac)")")")}"
build_temp="$(mktemp -d -t reelworks-android-XXXXXXXX)"
trap 'rm -rf -- "$build_temp"' EXIT
export XDG_CONFIG_HOME="$build_temp/config"
export RW_JAVA_SDK="$java_sdk" RW_ANDROID_SDK="$android_sdk"
python3 - <<'PY'
import json, os
from pathlib import Path
config = Path(os.environ['XDG_CONFIG_HOME']) / 'godot'
config.mkdir(parents=True, exist_ok=True)
settings = '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
for key, value in {'export/android/java_sdk_path': os.environ['RW_JAVA_SDK'], 'export/android/android_sdk_path': os.environ['RW_ANDROID_SDK']}.items():
    settings += key + '=' + json.dumps(str(Path(value).resolve())) + '\n'
(config / 'editor_settings-4.7.tres').write_text(settings)
PY
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="$build_temp/debug.keystore"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER="reelworksdebug"
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD
GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')"
"$java_sdk/bin/keytool" -genkeypair -keystore "$GODOT_ANDROID_KEYSTORE_DEBUG_PATH" \
  -storepass:env GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD \
  -keypass:env GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD \
  -alias "$GODOT_ANDROID_KEYSTORE_DEBUG_USER" -keyalg RSA -keysize 2048 \
  -validity 30 -dname 'CN=Reelworks Arcade Development,O=Private Free Play,C=GB' >/dev/null 2>&1
mkdir -p "$project_dir/builds"
"$godot_bin" --headless --path "$project_dir" --editor --import --quit 2>&1 | tee "$build_temp/import.log"
python3 "$project_dir/tools/check_godot_log.py" "$build_temp/import.log"
"$godot_bin" --headless --path "$project_dir" --export-debug Android \
  "$project_dir/builds/ReelworksArcade-debug.apk" 2>&1 | tee "$build_temp/export.log"
python3 "$project_dir/tools/check_godot_log.py" "$build_temp/export.log"
"$android_sdk/build-tools/36.0.0/apksigner" verify --verbose \
  "$project_dir/builds/ReelworksArcade-debug.apk"
"$android_sdk/build-tools/36.0.0/zipalign" -c -P 16 4 \
  "$project_dir/builds/ReelworksArcade-debug.apk"
(cd "$project_dir/builds" && sha256sum ReelworksArcade-debug.apk > ReelworksArcade-debug.apk.sha256)
echo "Built and verified $project_dir/builds/ReelworksArcade-debug.apk"
