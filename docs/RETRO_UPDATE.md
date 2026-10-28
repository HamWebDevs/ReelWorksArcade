# Version 0.2 — cabinet and bonus revision

This is a first redesign pass responding to playtest feedback. The cabinet now has a bulb-lined outlined marquee, reflective chrome rails, brighter printed fascia and color-coded feature lamps. Last Orders uses a perimeter pub trail that leaves the illustration visible and a printed cash progression strip. Shared reel controls remain mechanical and state gated.

Four bonuses now have separate decision sequences:

- Darts Dash: three individually stopped throws, a running total and three throw indicators. Each throw scores 20/60/120 from the visible lamp.
- Mystery Barrel: a saved shuffled cellar with +40, +80 and an empty barrel. Take up to two different picks or collect; an empty barrel ends play keeping the pot.
- Property Pick: choose a property with known rent, then separately bank rent, attempt a 50% double, or trade half the rent for construction icons.
- Paradox Mystery: up to three phase locks with guaranteed +10, 2/3 chance of +50, or 1/3 chance of +120. Failure ends the sequence keeping earned credits.

This does not make every bonus a bespoke minigame: other rule families still share their existing panels. The cartoon illustrations themselves remain the original vector artwork. Further character artwork and full-screen bonus choreography remain possible next improvements.

New entries use these rules. Already-saved old barrel/Paradox entries finish under their old rules; ongoing three-throw and cellar progress is saved. Debug builds use temporary signing keys, so Android may require uninstalling the old version before installing 0.2, which deletes local saves.

Validation: 2,397 gameplay assertions across 14 groups, 745 UI assertions, and 300,000 simulated paid spins passed on Godot 4.7.2. Observed virtual returns under the documented simulation policy were 465.784%, 1344.248%, and 642.091%; these remain unbalanced free-play design figures, not an advertised RTP. Rendered desktop inspection completed; no new physical-phone test was performed.
