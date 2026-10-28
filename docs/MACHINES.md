# Machine modules and published rules

Reelworks Arcade is an 18+ offline, fictional-credit simulator. Credits cannot be bought, transferred to another person, redeemed or withdrawn. The decorative cabinet jackpots are fictional credits; they are not a payout guarantee or a cash prize. Refill adds 1,000 credits for free whenever base play permits it.

The authoritative definitions are the JSON files in `data/machines/`. This document describes the implemented rules, rather than the mechanics of any historical commercial machine. The player-facing rules in each definition are available from that cabinet's instructions screen.

## Common reel rules

Each paid spin costs 10 credits. There are three reels, each with 30 stops; each unheld reel independently chooses a uniform stop. The animation shows the chosen result. The centre row is the only payline. Exactly three matching symbols pay; there are no mixed BAR awards, single-cherry awards or additional paylines. The adjacent rows show the actual neighbouring strip stops.

| Centre-line triple | Last Orders | Empire Estates | Time Shift |
|---|---:|---:|---:|
| Cherries | 20 | 25 | 15 |
| Lemon | 30 | 40 | 35 |
| Brass Bell | 60 | 75 | 80 |
| BAR | 100 | 150 | 120 |
| Red Seven | 200 | 250 | 300 |
| Themed symbol | Lucky Bell: 500 | Construction: 750 | Clock: 1,000 |

The three centre symbols also contribute their overprints: Lemon 1, Brass Bell 2, Red Seven 3, other symbols 0. Add these numbers to the persistent trail meter. Crossing a whole trail length opens the feature board; excess meter steps carry over. Triple themed symbols also open the board and their specific bonus. An eligible triple award is retained in the board pot.

On a non-winning spin without board entry, the normal hold offer has probability 1/4. If that fails, the nudge offer has probability 1/5, for an unconditional nudge-offer probability of 3/20. Nudge quantity is uniform 1, 2 or 3. An earned Super Hold offer takes priority. Holds preserve exact stop indices on the next spin. Nudges alter one reel by one physical strip index with wraparound, consume one nudge, and evaluate the centre line. A nudge win ends that offer; it does not add another trail-number award.

COLLECT moves a finished award into the fictional bank exactly once. TRANSFER moves the entire bank into play credits. CANCEL clears a hold offer or ends unused nudges. Buttons are only enabled in valid states.

## Last Orders

The original pub cabinet has a 24-position winding Pub Crawl and warm brass, cream, green and orange glass. Its themed reel symbol is the Lucky Bell.

- Pub Crawl starts with six board moves. CONTINUE rolls 1–6 and moves that many positions around the loop. COLLECT can finish the board with its current pot.
- Darts Dash now gives three separately stopped throws, accumulating all three scores. Each throw cycles 12 numbered positions at 100 ms per position. STOP uses the displayed cursor: lamps 6/7 pay 120, 5/8 pay 60, and the other eight lamps pay 20. There is no hidden dart roll. See the application accessibility setting for its reduced-motion presentation.
- Three Lucky Bells open an explicit choice of Reel Skill, Cash Climb or Cash Pot alongside board entry.
- Mystery Barrel starts at 20 and shuffles +40, +80 and empty between three barrels on entry. Pick up to two different barrels or collect early. Empty ends the raid keeping the pot. The hidden order and opened barrels survive interruption.
- Last Call Streak has a uniform 3–6 reveals. Reveal number `n` pays `n × X`, with `X` drawn uniformly from 10, 20, 30. CONTINUE advances each reveal.
- Super Hold provides three free attempts with real reel holds, ending on the first triple. It then earns two additional hold offers during base play.
- Cash Ladder offers a collectable pot and strict HI/LO predictions described below.

## Empire Estates

The original city cabinet uses emerald, navy, cream and gold, with a 20-position District Circuit. Its six-symbol paytable and stop distributions differ from Last Orders.

- Each board turn chooses Canal Quarter, Foundry Row or Lantern Heights, indexed 0/1/2. Roll `r` uniformly from 1–6; the destination advances `r + route_index`. The selected district also receives `r` construction progress.
- Reaching seven district progress unlocks its building, adds 20/40/60 credits for that route, and subtracts seven progress. District progress and unlocked buildings persist across features.
- Each centre Construction symbol adds one construction icon. Property Pick also adds one icon and unlocks the selected building. Choose rent of 40/60/80 according to the card, then a separate development decision: bank rent; double it with probability 1/2 (otherwise base rent); or take half rent and two additional construction icons.
- Building Bonus consumes construction icons and increases the board multiplier by `1 + floor(icons/3)`, capped at ×4, plus a 20-credit base award. Multiplier changes apply when returned feature awards enter the board pot.
- Auction Offer starts at 40. COLLECT accepts the current offer. Each CONTINUE has probability 2/3 of adding 40, or 1/3 of losing that offer. Four successful raises finish the auction.
- Rent Rush uses the streak rule, adding `10 × unlocked_building_count` to each reveal. Empire Streak instead adds `5 × construction_icons` to each reveal.
- Tycoon Trail is the numbered cash ladder. Bonus Exchange removes the current board pot and uses it as the ladder's initial pot, with a minimum of 40. The original pot cannot also be collected.

The branching interaction changes movement and maintains three separate district-progress values. It is not a full property-trading or ownership simulation.

## Time Shift

The original clock-and-coil cabinet uses violet, blue, cyan and orange. Its 24-position Time Circuit is divided into Past (positions 1–8), Present (9–16), and Future (17–24).

- Board movement wraps around continuously. The landing position determines the current era and its printed feature squares.
- Three Clock symbols trigger Time Jump. Choose an era: jump to its first square, then launch Rewind, Temporal Hi-Lo or Temporal Surge respectively.
- Rewind grants one charge and a 20-credit bonus. During permitted base play, the charge restores the saved reel positions from before the most recent paid spin and evaluates that explicit bonus once. A charge is consumed before any award; closing/reopening does not replenish it.
- Temporal Hi-Lo uses the same transparent 1–12 gamble model as Cash Ladder, with a clock presentation.
- Temporal Surge uses the streak rule, adding 0/10/20 per reveal in Past/Present/Future.
- Super Shift offers nine real nudges, ends at the first triple or COLLECT, and upgrades the board multiplier by one, capped at ×4.
- Paradox Mystery now offers three phase-lock decisions. Stable adds 10 guaranteed; Surge adds 50 with probability 2/3; Rift adds 120 with probability 1/3. Failure ends the sequence, keeping its pot. All three successes complete it. Existing saved pre-update Paradox features retain their previous rules until completed.

## Shared feature rules

The JSON `features` list controls the pool selected by a mystery square. Every listed entry has equal probability. Some feature names are themed variants of the reusable rule families; the implementation intentionally shares the underlying state machine.

| Feature | Implemented rule |
|---|---|
| Reel Skill | Twelve-position visible stop, using the Darts Dash 20/60/120 table; additionally sets reel 3 to that lamp's zero-based strip index and adds any resulting triple. |
| Win Spin | Uniformly select one of the six payable symbol IDs, place a matching triple, award its paytable amount. This declared bonus is separate from ordinary spin outcomes. |
| Super Hold | Up to three free spins with preserved selected reels; first triple ends it; earn two later hold offers. |
| Super Nudges | Six one-stop nudges; first triple ends it. Board nudge squares substitute their printed allowance. |
| Cash Climb | Strict uniform 1–12 HI/LO ladder; details below. |
| Mystery Bonus | Uniform 20/40/80/120 after choosing any cover. |
| Cash Repeater | Start with at least 40; 1/2 chance of +40 each continue; a failure ends while keeping all accumulated credits; at most five successful repeats. |
| Feature Shot | Stop on lamps 6/7 to enter a streak, 5/8 for 40, or another lamp for 10. |
| Add Again | Add the current board pot once, with minimum base award 20; current multiplier applies. |
| Extra Life | Add 20 base credits and one protection against a later wrong/equal HI/LO result. |
| No Lose | Add 20 base credits and protection against the next wrong/equal HI/LO result. |
| Lucky Seven | Uniform 1–12 draw; 7 pays 200, other results pay 20. |
| Streak Feature | Uniform 3–6 reveals; reveal `n` pays `n × uniform{10,20,30}`. |
| Cash Pot | Uniform award from 20,30,40,50,60,70,80,90,100. |
| Feature Upgrade | Increase current board multiplier by one up to ×4; add 20 base credits. |
| Bonus Selector | Player explicitly selects Reel Skill, Cash Climb or Cash Pot. |

A board opens with six moves. Cash squares add the printed award multiplied by the board multiplier. LIFE and UPGRADE squares grant their modifier; AGAIN adds one move, with remaining moves capped at 12. Board feature awards return to the board pot and use its current multiplier. This means a complete board pot may exceed the decorative triple-symbol jackpot. It is not a cap on all possible feature totals.

HI/LO initially draws a uniform integer 1–12. Each prediction draws another independent uniform 1–12. With current number `c`, HI succeeds with probability `(12-c)/12`, LO with `(c-1)/12`, and equality has probability `1/12` and loses unless protected. HI is disabled at 12 and LO at 1. A correct prediction doubles the pot to the machine jackpot cap. Reaching that cap or six successful predictions completes the ladder. A No Lose protection is consumed before an Extra Life; either retains the pot on one losing result and uses the new number for the next prediction. COLLECT keeps the current pot; EXCHANGE ends the ladder with half the pot, rounded down. Exchanging a base win first opens a cash ladder with that value.

## Adding an inert machine module

1. Copy an existing JSON file, give it a unique lowercase `id`, and edit names, colors, strip arrays, symbols, paytable, trail and feature pool.
2. Keep exactly three reel arrays and a matching `trail_length`/`trail` count. Every advertised winning symbol must appear on all three strips. `symbols.<id>.prize` must match `paytable.<id>`.
3. Use existing feature IDs listed by `MachineLibrary.FEATURE_IDS`. New gameplay code requires development; arbitrary scripts in a module are never executed.
4. Place the file in `user://machines/` and restart. In the desktop Godot editor, **Project → Open User Data Folder** finds that directory. Android's app data is private; use the debug build's developer tooling or package a built-in definition. There is no in-app file-picker installer in this version.
5. Existing repository SVG artwork paths can be reused for a private module. Keep the asset licensing appropriate. Custom-art import and a friendly module installer are future work.

The loader rejects files over 256 KiB, invalid types, impossible advertised triples, unsupported features, invalid chance pairs, mismatched trail lengths and duplicate IDs. It loads built-ins first, so a module cannot replace a built-in by reusing its ID. Default exported JSON files contain no credentials or executable scripts.

## Historical research boundary

The supplied Arcade History pages were reachable during development and confirmed their catalogue titles and dates:

- [Back to the Features (2004), Vivid Gaming](https://www.arcade-history.com/game/40136/back-to-the-features)
- [Atlantic (2003), Vivid Gaming](https://www.arcade-history.com/?id=15674&n=atlantic&page=detail)
- [Happy Fruits (2000), Bell-Fruit Games](https://www.arcade-history.com/?id=11557&n=happy-fruits-model-pr1011&page=detail)

The supplied [Fruit-Emu image page](https://www.fruit-emu.com/forums/gallery/image/3328-monopoly-double-moneyjpg/) timed out. No visual or gameplay claim is based on successfully examining that image. This project's original data, art and gameplay were authored from the user's broad cabinet-era design requirements. No ROM, historical reel strip, audio recording, franchise character or commercial cabinet composition was downloaded or included.

The simulation output reports the actual policy and sample results. These rules make no advertised overall RTP claim. An overall return depends on the feature/hold/gamble strategy, including timing decisions, and cannot be inferred from the triple paytable alone.
