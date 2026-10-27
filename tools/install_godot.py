#!/usr/bin/env python3
"""Install the exact official Linux editor and matching Android export templates.

No sudo is needed. Verifies release asset SHA-256 digests supplied by GitHub
when available and exact advertised sizes. Uses inherited HTTPS proxy settings.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import tempfile
import urllib.request
import zipfile

VERSION = "4.7.2"

def install_asset(asset, destination):
    digest = hashlib.sha256()
    with urllib.request.urlopen(asset["browser_download_url"], timeout=120) as response, destination.open("wb") as output:
        while chunk := response.read(1024 * 1024):
            output.write(chunk)
            digest.update(chunk)
    if destination.stat().st_size != asset["size"]:
        raise RuntimeError(f"Incomplete download: {asset['name']}")
    expected = asset.get("digest", "") or ""
    if expected.startswith("sha256:") and digest.hexdigest() != expected[7:]:
        raise RuntimeError(f"Checksum mismatch: {asset['name']}")
    print(f"Downloaded {asset['name']} (sha256 {digest.hexdigest()})", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, default=Path.home() / ".local/bin")
    args = parser.parse_args()
    args.directory.mkdir(parents=True, exist_ok=True)
    request = urllib.request.Request(f"https://api.github.com/repos/godotengine/godot/releases/tags/{VERSION}-stable", headers={"User-Agent": "ReelworksArcade-build"})
    release = json.load(urllib.request.urlopen(request, timeout=60))
    assets = {asset["name"]: asset for asset in release["assets"]}
    with tempfile.TemporaryDirectory(prefix="reelworks-godot-") as temp:
        temp = Path(temp)
        editor_name = f"Godot_v{VERSION}-stable_linux.x86_64.zip"
        install_asset(assets[editor_name], temp / "editor.zip")
        with zipfile.ZipFile(temp / "editor.zip") as archive:
            binary = archive.read(f"Godot_v{VERSION}-stable_linux.x86_64")
        executable = args.directory / "godot"
        executable.write_bytes(binary)
        executable.chmod(0o755)
        templates_name = f"Godot_v{VERSION}-stable_export_templates.tpz"
        install_asset(assets[templates_name], temp / "templates.tpz")
        data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
        target = data_home / f"godot/export_templates/{VERSION}.stable"
        target.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(temp / "templates.tpz") as archive:
            for filename in ("android_debug.apk", "android_release.apk", "android_source.zip", "version.txt"):
                (target / filename).write_bytes(archive.read("templates/" + filename))
        print(f"Editor: {executable}\nAndroid templates: {target}")

if __name__ == "__main__":
    main()
