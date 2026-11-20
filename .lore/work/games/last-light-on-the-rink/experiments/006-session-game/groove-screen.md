# Groove control screen

## Frame and criteria declared before checks

This bounded screen compares ways to make and reuse a skating groove for Last Light on the Rink. The source pitch and creative provenance are in `record.md`, with discovery inputs from commit `dbf1467f6c4c2f80ab968ab8ccb8d9bfea93d612`. The six alternatives were technical comparisons during the build, not choices offered to the player. None produced a human play result.

The pitch promises that skating with an explicit edge action authors the line, shallow approach seats the blade, and leaning out exits voluntarily. The discovery pitch proposed reverse entry as a later unlock, so this scratch screen used forward entry only. The full evening deliberately gives the player shallow entry in either direction immediately, rather than reserving counterflow for a hypothetical second show. The expressive opportunity is to make different paths and choose when to reuse and leave them. A separate performance starts with no inherited cuts. There are no followers, goals, audio, rewards, telemetry, or player tests in this screen.

Before checking: a survivor must (1) physically skate to author the line, not place it with a cursor; (2) allow different authored paths; (3) catch from a shallow forward approach without a catch button and permit voluntary directional exit; (4) isolate cuts across separate performances. A direct rule contradiction excludes only the specified version, not all possible hybrids. Satisfying these rules does not demonstrate skating feel, enjoyment, replay, or full-game viability. Where rule descriptions omit reset, reset is not assumed impossible.

| ID | Alternative and hypothesis | Prediction / counterevidence | Main risk and diagnostic |
|---|---|---|---|
| G1 | Paint a route by cursor, then skate into it. Drawing might enable precise composition. | A cursor can create a route with the skater stationary / requires skating to create it. | Loses embodied authorship; use the stationary-skater counterexample. |
| G2 | On-rails autopilot takes over along a caught route until its endpoint. Predictable paths might make staging legible. | An outward lean before the endpoint does not exit / it does immediately exit. | Control loss; use a mid-route outward-lean counterexample. |
| G3 | Record and replay fixed movement inputs as the line's later behavior. A familiar performance might be easy to reuse. | Identical input playback drives the path rather than the blade's present approach / present approach independently changes seating. | Replay is not responsive ice; compare identical replay with different approach. |
| G4 | Every movement cuts a groove, with no explicit edge action. Continuous marks might encourage experimentation. | A glide without edge input still authors a line / it leaves no line. | No distinction between glide and carving; use a no-input glide counterexample. |
| G5 | Hold edge to carve, automatically catch a nearby forward-aligned groove, steer outward to release. One-way entry might make intentional re-entry and expressive departures legible. | Distinct cuts, shallow catch, rejection of reverse approach, release, and clean reset are observable / any controlled check fails. | Accidental catches or overbearing steering; run controlled Godot checks, leaving feel untested. |
| G6 | Hold a separate catch button to seat on a groove. An explicit command might avoid unwanted catches. | Shallow contact without that button does not seat / it seats automatically. | The approach no longer suffices; use a no-button shallow-approach counterexample. |

Controlled checks cannot establish that a mechanic is enjoyable. No selection of a winner follows solely from this screen.

## Screen results

The following are rule-level counterexamples, not observations of playable builds or judgments of fun:

| ID | Disposition | Counterexample against the declared criteria |
|---|---|---|
| G1 | Excluded | Keep the skater stationary and drag the cursor: a groove exists without skating. This contradicts physically authored ice. |
| G2 | Excluded | Catch the rail, then lean outward before its endpoint: this version's autopilot continues to the endpoint. That contradicts voluntary exit. An autopilot with immediate exit would be a different rule. |
| G3 | Excluded | Start the same fixed input replay from different approaches: the replay, rather than current blade contact, specifies the behavior. The pitch explicitly rejects fixed-input replay. A separate physical groove made while recording would be another version. |
| G4 | Excluded | Glide with edge unheld: movement still cuts a groove. The pitch explicitly distinguishes glide from holding edge to cut. |
| G5 | Scratch playable; controlled checks passed, manual interaction unverified | The headless checks below exercise the specified cases. They do not establish faithful curved tracking or feel. |
| G6 | Excluded | Make a shallow forward approach with the catch button unheld: no catch occurs, although the pitch specifies seating by approach. A button that only reduces accidental catches without being required would be a different rule. |

Separate-performance isolation is not a reason for excluding G1, G2, G3, G4, or G6: none of their specified rule differences precludes a reset. Path variety is likewise not by itself contradicted by any of these descriptions. These are pitch-fit exclusions, not evidence that the excluded designs are worse games.

### G5 scratch and checks

Godot `4.7.2.stable.arch_linux.ed1daf0bf`, Linux. Scratch is `/tmp/opencode/groove-screen/`, outside the repository and not a runtime dependency or shipped prototype. Script SHA-256 at the check was `c0d3cb057c96999d57b6717db0ad707f0d15f12537f64e17bf8963599b02d8cd`. Scratch is disposable: the following commands require that exact local script and do not regenerate it from a fresh checkout.

- Automated: `godot --headless --path /tmp/opencode/groove-screen --script res://g5.gd -- --test` exited 0 and printed `G5 checks: PASS`. Test-owned inputs checked one edge-held segment, no segment on free glide, distinct up/down steered cuts, aligned and shallow forward catch, perpendicular and reverse rejection, sideways exit, and an empty reset after prior segments. Inputs are deterministic; no seed applies.
- Interactive launch, **not manually verified**: `godot --path /tmp/opencode/groove-screen --script res://g5.gd`. Arrow keys steer, Shift cuts, sideways steering releases a catch, R resets. G5 is identified on screen. There is no menu, performance system, or production integration.
- This is a deliberately crude local-segment approximation, not real skate physics. Catch proximity is checked after movement; fast crossings can be missed. It changes direction from nearby aligned segments but does not project the skater onto the line. Branches, sharp curves, repeated traversal, edge boundaries, overlaps and release/re-entry timing are not covered. The single-step tests do not prove the blade follows a curved groove or supports a complete performance. The scratch has no audio and has not been evaluated for accidental catches, visual readability or feel.

## Interpretation and boundary

The five contradictions support excluding these exact rule definitions from this pitch. G5 remains an implementation candidate, not a winner: its controlled checks provide only narrow mechanical evidence, with no player enjoyment, desire to continue, voluntary replay, or comparative play evidence. The screen demonstrates that AI can identify explicit rule contradictions and run a few deterministic checks; it does not establish a useful design diagnosis or general AI capability.

The next technical question is whether a skated curved cut can be caught and followed continuously, then left intentionally without unwanted recapture. Check that behavior under controlled traces and only then assess feel with an appropriately authorized human session. Keep the eventual deliverable one normal game, not a six-variant menu. For layout, styling, visual hierarchy, responsive behavior, animation, or component feel, consult `@designer` with the file and goal.
