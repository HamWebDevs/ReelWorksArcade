# Engine, state and random model

`ReelEngine` is a UI-independent RefCounted model. `configure()` loads one validated definition; `act(action,value)` rejects actions not available in the current state. It returns a boolean and emits a presentation event only after mutation. `finish_spin()` is idempotent outside SPINNING. The UI never assigns prizes or randomly chooses stop positions.

A paid START debits the stake once and selects unheld center indices uniformly and independently from each configured strip. It saves the resulting SPINNING state before animation. Held indices are untouched. Animation moves to those indices with staggered deceleration; its completion requests evaluation. Restoring SPINNING evaluates those already-selected indices, never recharges or rerolls. Static reel neighbors are actual adjacent strip positions with wraparound. Nudges mutate one index by ±1, consume allowance and evaluate that line.

## Random generator

`SimRng` uses Park–Miller with multiplier 48,271 and modulus 2,147,483,647. Internal state is 1…2,147,483,646. Seed normalization is `seed mod (modulus−1) + 1`; a negative/default seed mixes the current system milliseconds with monotonic microseconds. This is a reproducible simulation PRNG, not a cryptographic source. It has no player history or payout compensation inputs.

Each draw computes `(state × 48271) mod 2147483647`. Arithmetic fits a signed 64-bit integer. Bounded integers use rejection sampling over the full available population before modulo, avoiding modulo bias. Integer RNG state is serialized as a decimal string, with draw count, so JSON conversion cannot truncate it. The same configuration, seed and ordered actions produce the same results on desktop and Android. A test verifies save/restore stream continuation.

Events consume successive pseudorandom draws; independence means no outcome adjustment based on previous wins, balance, animated near misses or a target return. It does not mean cryptographic unpredictability. The only selected winning strip arrangements occur in the explicitly documented **Win Spin** bonus. Ordinary spins never rearrange strip stops to fabricate near misses.

## State and ledger

Base play uses IDLE, HOLD_OFFER, SPINNING, EVALUATING, NUDGE_OFFER and AWARD_COLLECTION. FEATURE_ENTRY leads to FEATURE_ACTIVE; hi-lo uses GAMBLE. EVALUATING is synchronous and cannot receive UI input. RECOVERY is reserved and is not accepted as a persisted playable state. The model validates schema, machine ID, legal state, stop bounds, nonnegative ledger, required bonus fields and RNG before restoring.

All prizes are integer fictional credits. Base awards and completed bonus pots wait for COLLECT or their explicit exchange. Awards enter the bank through `_credit_bank()` once, updating statistics and a serial. Consumed bonus state is cleared/replaced in the same synchronous action, so a repeated COLLECT cannot repeat that award. A nested bonus returns its amount into its saved board context; it does not also credit the bank. Saving occurs immediately after every accepted action and spin evaluation.

The UI additionally debounces human input for 110ms and disables controls during mechanical reel animation. It captures hold flags before the engine consumes them. Super Hold and Win Spin bonus outcomes also animate to actual stops. Debouncing is not relied on for ledger integrity; direct rapid engine calls are tested.

## Persistence and interruptions

`SaveStore` writes `{schema,payload}` to a sibling temporary file, flushes/closes it, moves the prior save to `.bak`, then renames the new file into place. Loading uses the primary or last valid backup and quietly skips malformed JSON. Saves include each cabinet's ledger, RNG, exact stops, pending feature/board context, stats, district/era progress, preferences, current cabinet and unlocked machine IDs. There is no cloud save or network synchronization. Android backups are disabled in the export preset.

A pause notification and navigation/exit also save. A pending feature resumes as the same decision; precomputed streak length, pot, life protection and RNG are preserved. File-system corruption recovery may roll back to the last complete snapshot; this is a local free-play simulator, not a tamper-resistant financial ledger. Restore tests cover interruption before evaluation, within features and after collection.

## Features

See [MACHINES.md](MACHINES.md) for every common and machine-specific probability and interaction. Skill STOP takes the visible zero-based cursor (0…11). The player sees lamps 1…12; displayed lamps 6/7 are the best outcome. The cursor updates every 100ms and is not randomized after input. Reduced motion freezes it at displayed lamp 1, producing the declared lower award; this convenience is stated in the rules. Reel Skill also sets reel 3 to the selected strip index. Feature Shot has its separate published table.

Board squares apply their printed cash/modifier/bonus rules, not arbitrary independent animation rewards. Empire route selection changes the destination offset and progress of the chosen district. Time's era comes from board position and time-jump choices; it changes the feature selected or reveal award. Rewind consumes its charge before evaluating the recorded positions. Extra Life and No Lose protect one failed/equal hi-lo draw and are consumed in the saved board context.

## Simulation interpretation

`tests/simulation.gd` uses the production model and a separately seeded player-policy RNG. It plays legal inputs to completion after each paid spin, detects loops/stuck states with a 300-transition budget, tracks zero and nonzero wins, counts events and named bonuses, and checks nonnegative ledger. It funds play upfront rather than treating refills as prizes. Virtual return is `100 × banked awards / paid stakes`. Its policy and seeds are embedded in the report. Strategy affects return, especially holds, nudges, hi-lo and timing; one policy estimate is not a universal RTP claim.
