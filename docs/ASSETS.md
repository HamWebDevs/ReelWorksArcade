# Asset provenance and permissions

All cabinet glass, reel symbols and application icon are original vector illustrations authored for Reelworks Arcade. `tools/generate_assets.py` is their complete, deterministic source. The illustrations depict an invented crooked timber pub, an original stepped civic skyline, and an analog clock apparatus. No original-machine artwork, franchise characters, logos, ROMs, photographs, recordings, tracing, or stock assets are used. All graphics are SVGs rendered through Godot's native SVG importer. They are deliberately designed to remain crisp at phone resolutions.

All WAV files are original mathematical synthesis produced by the same generator: sine waves, harmonics, deterministic white noise, envelopes and original short note sequences. They are mono 22,050 Hz, 16-bit PCM to reduce decode overhead and storage. `ambient_*.wav` files are seamless four-second low-volume harmonic loops; their WAV import loop mode must be enabled by the audio player if desired. Their notes are integral cycles in four seconds. Spin noise is a one-shot, intended to accompany the normal reel animation. These are not recordings of historical machines or music samples.

The newly authored artwork, audio, and generator may be used, modified, and distributed with this project, including commercially. Copyright (c) 2026 Reelworks Arcade contributors. The project owner may choose a repository-wide licence before publication; no third-party clearance is required for these newly authored media. Do not represent fictional decorative credit amounts as monetary prizes.

The four bundled font files are unmodified DejaVu fonts: `display.ttf` = DejaVu Serif Bold, `body.ttf` = DejaVu Sans, `bold.ttf` = DejaVu Sans Bold, `mono.ttf` = DejaVu Sans Mono. Their upstream Bitstream Vera/DejaVu font licences, copyright notices, and packaging notices are included verbatim in `assets/fonts/LICENSE-DejaVu.txt`. They permit bundling and use subject to those notices. Font names are only local asset filenames, not modifications to the fonts' internal names.

## Generated files

- `assets/cabinets/last_orders.svg`, `empire_estates.svg`, `time_shift.svg`: 680×580 glass art.
- `assets/symbols/cherry.svg`, `lemon.svg`, `bell.svg`, `bar.svg`, `seven.svg`, `special.svg`: common symbols, 128×128. `tankard.svg` is an additional pub decoration.
- `assets/symbols/last_orders_special.svg`, `empire_estates_special.svg`, `time_shift_special.svg`: original machine-specific symbols: a ribboned Lucky Bell with a clover, a civic building, and an analog clock.
- `assets/icon.svg`: original cabinet application icon.
- `assets/audio/click.wav`, `stop.wav`, `spin.wav`, `credit.wav`, `move.wav`, `win.wav`, `feature.wav`, `collect.wav`, `lose.wav`, `jackpot.wav`: original effects.
- `assets/audio/ambient_last_orders.wav`, `ambient_empire_estates.wav`, `ambient_time_shift.wav`: ambience.

Regenerate from the repository root with `python3 tools/generate_assets.py`. The generator reads the documented system DejaVu fonts only to copy their unmodified distributions; all other outputs require only Python's standard library. If fonts are absent, existing bundled fonts remain intact.

Godot 4.7.2 is MIT-licensed; its official engine notice is included at `assets/licenses/Godot.txt`. The Android export explicitly includes that notice and the DejaVu font notice in the resource bundle. Review all engine/platform third-party notices again before a public release.
