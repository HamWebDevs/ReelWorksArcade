# Reelworks Arcade

An original, playable, offline Godot collection inspired by the hardware and play vocabulary of British pub fruit machines. **18+ simulated gambling; unlimited fictional credits only.** No payments, advertisements, accounts, network service, purchasable credits, transferable balance or redeemable prizes.

This repository contains three working cabinets: **Last Orders**, **Empire Estates** and **Time Shift**. It is a substantial playable development build, version 0.1.0, with original vector glass, mechanical reel animation, native touch controls and synthesized audio. It is not a finished commercial release. Read [the development report](docs/DEVELOPMENT_REPORT.md) for verified results and remaining polish/balancing work.

## Download the Android APK

Open [Android debug build in GitHub Actions](https://github.com/HamWebDevs/ReelWorksArcade/actions/workflows/android.yml), select a successful run, and download **ReelworksArcade-debug** under **Artifacts**. Sign in to GitHub first. Extract the ZIP and open `ReelworksArcade-debug.apk` on your phone. The APK is at the top level of the ZIP.

## Play and install

Open `project.godot` in **Godot 4.7.2 stable** and press F6/F5, or run:

```sh
godot --path .
```

The local Android deliverable, when successfully built, is `builds/ReelworksArcade-debug.apk`. Follow [Android installation and build instructions](docs/ANDROID.md) for a Samsung Galaxy S20+ running Android 13. The current export is ARM64. All three machines are unlocked, and each starts with 1,000 fictional credits. Tap **PLAY CABINET** from the arcade. **RULES** shows that machine's published rules and paytable; **STATS** shows its individual history.

| Control | Behavior |
|---|---|
| START | Deduct the displayed stake, select independent reel stops, animate and evaluate. |
| HOLD 1/2/3 | When offered, preserve selected reel indices for the next paid spin. |
| NUDGE up/down | Consume one allowance and move that reel exactly one strip stop. |
| COLLECT | Bank the available award, or finish a board/bonus at its available pot. |
| EXCHANGE | Enter the cash ladder from an award; from that ladder take its explicit half-value alternative. |
| HI / LO | Predict an independent integer 1–12; equality loses unless protected. |
| FEATURE START | Enter a bonus board earned through overprints or three themed symbols. |
| CONTINUE / choices / STOP | Operate the active board or bonus under its displayed rules. |
| REWIND | Spend an earned Time Shift charge to restore the preceding spin's recorded stops. |
| CANCEL | Decline holds or end unused base nudges. |
| FREE CREDITS / BANK → PLAY | Refill for free, or move the fictional bank into play credits. |

Only valid controls illuminate. Keyboard alternatives: Space START, 1/2/3 HOLD, C COLLECT, H/L HI/LO, Escape Back. Android Back closes a detail screen or returns to the arcade; leaving the arcade exits. Reels settle before navigation leaves an active spin. **ENLARGE BOARD** opens readable glass inspection and offers reel inspection. Sound, ambience, mute, vibration, reduced motion, reduced flashing, contrast and optional 20-minute reminders are under the settings button.

## Machines and mathematics

- **Last Orders:** 24-square Pub Crawl, Lucky Bells selector, Darts Dash, Mystery Barrel, Super Hold, cash ladder and Last Call Streak.
- **Empire Estates:** 20-square District Circuit with three player-selected progress routes, persistent buildings and construction icons, Property Pick, Auction Offer, Building Bonus, Rent Rush, Tycoon Trail, Empire Streak and Bonus Exchange.
- **Time Shift:** 24-square loop divided into Past/Present/Future, triple clocks, era selection, Temporal Hi-Lo, earned Rewind, Temporal Surge, Super Shift and Paradox Mystery.

All 16 requested reusable bonus rule families are implemented; 33 named common/themed feature IDs share those rule families. They have real engine transitions and payouts. The degree of visual specialization varies: dartboard, clock, barrel and property props are present, while several reveals and ladders share the cabinet's decision panel.

See [published machine rules](docs/MACHINES.md) and [engine and randomness documentation](docs/ENGINE.md). Three matching center symbols pay the exact table. Overprinted numbers advance the trail. The engine commits outcomes independently of animation and saves the entire random stream and pending bonus state. There is no proprietary compensated payout algorithm or near-miss manipulation.

The development simulation reports observed virtual returns under one declared player policy. These generous free-play feature tables are **not balanced or advertised to any target RTP**. Board totals can exceed the decorative triple-symbol prize.

## Project structure

```text
scenes/arcade/         Main native Control scene
scenes/cabinet/        Reusable illustrated feature-glass scene
scenes/reels/          Reusable mechanical reel-window scene
scenes/features/       Original bonus prop scene
scripts/core/         Deterministic RNG and atomic save store
scripts/gameplay/     Pure state machine, ledger, reels and bonus rules
scripts/machines/     Validated data/module loader
scripts/ui/           Arcade, cabinet rendering, props, audio and controls
data/machines/        Three original JSON definitions
assets/               Original SVG/WAV media and licensed DejaVu fonts
tests/                Headless engine/UI tests, simulation, visual capture
tools/                Reproducible assets/data and exact Android build tools
docs/                 Rules, mathematics, provenance, build and release notes
.github/workflows/    Android APK artifact pipeline
builds/               Ignored local APK, test reports and screenshots
```

Definitions are data modules. The loader reads built-ins and validates extra JSON modules in `user://machines/`; no arbitrary scripts are executed. Modules can reuse the existing rule families without changing the shared engine. There is no in-app module installer or external artwork importer yet. See [module authoring](docs/MACHINES.md#adding-an-inert-machine-module).

## Verify

Use the exact 4.7.2 executable for all commands:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/test_runner.gd
XDG_DATA_HOME=/tmp/reelworks-ui-test godot --headless --path . --script tests/ui_smoke.gd
godot --headless --path . --script tests/simulation.gd -- --spins=100000
```

The simulation runs 100,000 paid spins **per machine** and their actual feature transitions, outputting `builds/simulation-results.json`. It uses a separate policy RNG, records distributions and feature/event frequencies, and fails for stuck states or accounting inconsistencies. Reproduce another stream with `--seed=12345`. These development scripts are excluded from APK exports.

UI tests use a separate user-data directory because they exercise real save calls with controlled fixtures. On Windows, set `XDG_DATA_HOME` or use an isolated OS profile appropriately before fixture tests; the engine-only suite uses separate test save paths. For rendered screenshots under a graphical desktop/Xvfb:

```sh
XDG_DATA_HOME=/tmp/reelworks-visuals godot --path . --audio-driver Dummy \
  --resolution 720x1440 --script tests/visual_capture.gd
```

Outputs go to `builds/screenshots/`. Inspect them at phone size as well as full size. Automated logic tests do not establish phone performance, physical touch comfort or Android lifecycle behavior on a device.

## GitHub APK builds

The [GitHub Actions workflow](.github/workflows/android.yml) installs exact Godot 4.7.2/templates, Java 17 and Android SDK 36, imports/validates, runs engine/UI tests and 300,000-spin simulation, generates a temporary debug key, exports and verifies the APK, and uploads a 7-day artifact. The owner has authorized hosting this project in a public repository. It never creates a release or publishes to a store. No release credentials are committed.

The source destination is [HamWebDevs/ReelWorksArcade](https://github.com/HamWebDevs/ReelWorksArcade). See [Actions](https://github.com/HamWebDevs/ReelWorksArcade/actions/workflows/android.yml) for current hosted build results. Local and hosted builds use the same export script.

Read [asset provenance](docs/ASSETS.md), [Android/AAB steps](docs/ANDROID.md) and [the future publication checklist](docs/PUBLICATION_CHECKLIST.md). The project's original source/media are available to the project owner for further development; no public source licence is selected. Preserve the bundled font notices and Godot engine attribution when distributing.
