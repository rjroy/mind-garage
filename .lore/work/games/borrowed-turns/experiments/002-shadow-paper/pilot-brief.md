---
title: "Borrowed Turns: one-shove shadow-paper pilot"
date: 2026-11-15
status: draft
tags: [game-design, visual-experiment, interface, shadow-paper]
related: [.lore/work/games/borrowed-turns/experiments/001-hook-discovery/presentation-intent.md, .lore/work/games/borrowed-turns/design/art/borrowed-turns-shadow-paper-brief.md, .lore/work/games/borrowed-turns/experiments/001-hook-discovery/revision-02-executable-rules.md]
---

# One-shove shadow-paper pilot

## Purpose, provenance and boundary

Test whether a recognizable **pushing action-shadow** makes capture, ownership, release and backlash more appealing, understandable and satisfying in the existing encounter. This is one reversible visual experiment for Ronald, not a six-style comparison or a production art decision.

- Plain immutable baseline: `ba3ab7a`, after `mind-garage-84b` at `29cd5ef` and `mind-garage-2nx` at `ba3ab7a`.
- Ronald supplied the art discussion/image at `4727f30`. His clarification in `presentation-intent.md`, recorded at `66f90e8`, makes those notes intent/musings, not binding implementation requirements. Preserve them unchanged. The image is a construction/mood reference, not a gameplay composition or approved production asset.
- The current go-ahead covers primitive-based prototype code and in-game presentation integration in this pilot. It does not authorize new images, finished artwork, Blender, dependencies, paid services, a production pipeline or final art-direction selection. The selected description below is an agent-owned working interpretation under that authorization; no additional concept-generation round or player interview is required.
- Keep rules, fixture, target geometry, camera, AP/MP, capture frequency, deadline, controls, legality and preview outcomes fixed for the first comparison. This is our comparison control, not a claim that present geometry is immutable. Any later geometry experiment must be separately declared.
- Invert is removed. Do not reintroduce pull, its toggle/flag/state, or an unlock system as part of this pilot.
- This invocation writes the brief and new test-owned files only. A separate setup invocation supplies the safe empty interface, an independent tester establishes assertion RED, and a later implementation invocation supplies the real controller, renderer and UI integration.

FY3 remains open for Ronald's visual review even after technical checks pass. The next mechanics bead `mind-garage-7am` remains blocked on FY3. Agent critique, passing tests, rendered evidence and Ronald's personal enjoyment are separate evidence, not substitutes for one another or general audience findings.

Implementation clarification: the authorized candidate defaults to paper, with `--presentation=plain|paper` and a **Paper pilot** view switch. Switching views preserves model/selection/history and resets only presentation generation/cues. The controller contract below is unchanged. Existing non-shove feedback remains; runtime primitive paper figures cover the player and shove sources only. A reusable actual-scene evidence tool supplies labeled controlled stills/motion and a state/fixture manifest. Lethal backlash retains the complete model footprint but collapses the visible gesture at the player, avoiding an implication that later victims took damage after resolution stopped. These choices do not select final art direction.

### Ronald's implementation-medium concern

During implementation Ronald permitted continuation while explicitly warning:

> okay ... carry on ... but I reserve the right to say "I told you so". Past experiments at using "primitives" as resulted in inexplicible results that cannot be judged for their visual acquity. When that's the goal here ... I have doubts

This is a material experimental-validity concern, not a request for more state-machine checks. A prototype that merely contains polygons cannot establish the appeal of theatrical paper art. Judge whether the actual gameplay-scale figures, pressing silhouette, construction and motion communicate the proposed treatment. If the primitive candidate remains too schematic, record an implementation-medium limit and do not interpret an unfavorable reaction as evidence against the art direction. The runtime pilot does not reproduce the supplied image's textured materials, layered forest composition or cinematic lighting; those omissions limit the appeal question it can answer. Any change to an authored/generated asset route requires separate authorization, not automatic escalation inside this scope.

## Selected visual description

**The bodies are paper pieces; the borrowed pushing gesture is the moving subject.** Keep the current native HUD, square board, coordinates, tile markings and restrained mineral-green/ink/rust/teal palette. No forest set, cinematic perspective, texture production or environmental overhaul is needed.

Give the ordinary protagonist a narrow, angular coat silhouette and the selected shove pursuer a broader, squared stance. Use flat light-paper pieces with dark edges and limited internal shapes, not a spiky-haired caped hero or bobble-headed toy. Figures remain comparatively static apart from actual model-reported movement. Other ability kinds can retain baseline pawns/telegraphs; this is intentionally not a complete cast reskin.

The shove shadow is a compact, jointed arm ending in a broad palm with a distinct thumb gap. It must read as a pressing gesture in a paused frame, not merely a rectangle, arrow, energy projectile or scaled-up duplicate of the person. A small forward-press idle loop supplies anticipation; the committed beat unfolds that same gesture. Dense ink gives the shadow a different visual role from the light paper figure. Shape refinement happens in runtime primitives, not a new asset-generation workflow.

Choose **no ordinary cast shadows** for this first pilot. That is a bounded artistic interpretation of the notes, not a new permanent rule. Use the existing provisional artifact token as the held motif's anchor; do not settle a lantern as the artifact or introduce illumination/range mechanics.

## State and motion direction

| State | Working presentation | Must remain true |
| --- | --- | --- |
| Announce | A small pressing arm/palm loop belongs to an announcing shove source. | Draw complete threatened cells from `intentions`; idle motion does not change range or resolve an attack. |
| Capture | The current occurrence's gesture folds/detaches and travels from that source to the player's token. | The enemy body remains; only the captured occurrence loses its action-shadow. Invalid commands never produce this transfer. |
| Held | A compact framed palm motif persists beside the token, with the existing explicit deadline text. | It represents the stored snapshot, not a permanent theft of the source's ability. Do not rely on animation speed for urgency. |
| Release | The same gesture unfolds from the player toward the legal target and model footprint; actual damage/displacement follows model events. | No changed origin/range, no self-hit invented for release, and no new ability geometry. |
| Backlash | The held gesture breaks outward from the player, including a clearly readable self-hit. | Keep the model's full footprint, rust double-border warning and ordered consequences; do not portray it as a harmless release. |
| Enemy resolution | An uncancelled shove source executes the same pressing gesture along its emitted ray. | Use the actual event footprint/actor position; an enemy killed before acting has no execution cue. |
| Reannounce | A source eligible to announce again regains an action-shadow from fresh `intentions`. | A fresh source shadow can coexist with the previously captured, framed held shadow. A dead source cannot reannounce; its already-stored ability can still remain held. |

Replacement resolves the old discharge before any new transfer. If the model reports `capture_failed`, show the discharge and the existing failure explanation, but no acquisition animation. Player death similarly stops acquisition. Non-shove captures/releases keep their baseline feedback; they must not become new shadow abilities merely to fill this pilot.

The controller describes settled **after-state facts immediately** plus a finite transition plan. The renderer may temporarily withhold the settled held motif while its capture transfer is in flight, and suppress a source's idle loop while its execution cue runs. These are drawing decisions only. It must not alter stored state, announcements, model timing or the existing truthful preview/history.

## Layering, overlap and pausing

Draw board/scenery first, action shadows next, then authoritative tile markings, figures, IDs/health, inspection/selection and keyboard focus. Shadow ink must not hide the only indication of threat, overlap, self-hit, selected target or legal destination. Keep source/held idle gestures local and subdued; source inspection can emphasize its gesture/footprint instead of playing several equally large animations across the board.

The framed held motif distinguishes an older capture from the source's new announcement even when both depict the same palm. Preserve the explicit source identity, occurrence turn and captured turn in presentation data. Use deliberate release versus backlash shape/staging plus existing text/patterns, not color alone. Paused stills must remain interpretable at the actual gameplay scale, including 1024 × 720.

Presentation duration can differ between plain and paper feedback and is part of the presentation bundle being tested. Record it rather than claiming to isolate silhouette, motion or latency as individual causes. Do not use idle loops to keep input locked. Restart remains available during finite feedback, and old callbacks cannot restore stale work after it.

## Minimal controller contract

Planned implementation: `res://ui/shadow_presentation.gd`, a `RefCounted` without scene, model, filesystem, timer or rendering dependencies. It consumes detached model snapshots/events. It must never call `act`, compute rays/areas, decide damage/displacement, validate capture reach, or simulate a future turn.

| Method | Contract |
| --- | --- |
| `reset(snapshot: Dictionary, generation: int) -> void` | Deep-copy the latest settled facts, cancel all finite cues, restart visual phase and adopt this generation. Older generations are ignored; equal-generation reset is an explicit cancellation/restoration. Do not replay `snapshot.events`. Initial generation before reset is `-1`. |
| `observe(before: Dictionary, confirmed_command: Dictionary, after: Dictionary, generation: int) -> bool` | Accept only the current generation and a changed before/after transition. Return false and leave presentation untouched for unchanged snapshots or mismatched generations. On acceptance, replace the last finite plan, derive settled facts from `after`, build ordered tactical footprint cues plus shove acquisition cues from `after.events`, and return true. Only shove receives the hand animation. Caller invokes it only after a real successful model command; it does not run or revalidate gameplay. |
| `advance(delta: float) -> void` | Deterministically advance visual time and the finite plan. Ignore nonpositive delta. Consume elapsed time across successive cues, finishing finite work even while announcement/held loops persist. No asynchronous callbacks or model access. |
| `frame() -> Dictionary` | Return a deep, consumer-mutable copy of the complete minimal presentation state described below. Calls do not advance time. |

`frame()` always returns these keys, including before reset:

- `generation: int`.
- `announcements: Array[Dictionary]`: shove-only current announcement rows in model order, each `{source, kind: "shove", turn, cells}`. Turn is the snapshot turn; cells are copied from `intentions`. No captured/current-cancelled/dead occurrence is reconstructed from ability geometry.
- `held: Dictionary`: `{}` unless `snapshot.stored.ability.kind == "shove"`; otherwise the entire stored dictionary, detached. It remains valid if its source later dies, and carries source, ability, stored direction, captured turn and deadline unchanged.
- `cues: Array[Dictionary]`: the complete finite plan for the most recent accepted transition in model event order. Retain it for inspection after completion; a new observe/reset replaces/clears it. Each row has `type`, `source`, actual ability `kind`, `footprint_type`, `event_index`, `from: Array`, `to: Array`, and `cells: Array`. Types are `capture`, `release`, `backlash`, `resolve`. Event indices refer to originating model events. Bolt/burst entries preserve tactical feedback without introducing new shadow artwork.
- `cue: Dictionary`: `{}` when settled; otherwise the active plan row plus `progress: float` in `[0,1]`. Capture travels from the actual source position at acquisition to the actual player position, with empty cells. Release starts at the actual player position, ends at the confirmed target, and copies the subsequent player ray. Backlash starts at the player, has empty `to`, and copies the subsequent full player ray including self. Resolve starts at the enemy's event-time position, uses empty `to`, and copies that enemy's emitted ray. Rendering can orient gestures from these anchors/cells without deciding gameplay geometry.
- `busy: bool`: true only while a finite cue is active, never merely because an announcement or held motif exists.
- `loop_phase: float` in `[0,1)`: deterministic idle animation phase, separate from finite completion. Exact motion duration/curve is not a gameplay contract or a unit-test tuning constant.

Pair release/backlash markers with their subsequent player footprint in event order. Enemy ray/area events supply tactical `resolve` cues, with the hand animation restricted to shove. Track event-reported move/displace positions when resolving anchors, rather than assuming the final snapshot position is the historical origin. `capture_failed` and `loss` are outcomes, not invitations to invent a transfer; only actual shove `capture` events create capture cues. Do not infer acquisition from the command's selected source. Non-shove feedback shares the finite timeline so that mixed transitions neither hide it nor expose later aggregate effects early. This extends the original shove-only cue contract to correct FY3-C03; it adds no gameplay rule or non-shove art treatment.

No public playback-mode flag or alternate model API belongs in this controller. Plain/paper selection happens in UI integration. The eventual real UI may submit a new command only when its finite presentation gate allows it; `observe` replacing a plan also permits explicit cancellation/reconciliation without retaining an unbounded command history.

## Safe interface scaffold prerequisite, not behavioral RED

The component intentionally does not exist in this invocation. A separate setup writer must create **only a loadable safe empty interface**, not implement behavior: extend `RefCounted`; provide the exact four method signatures above; initialize generation to `-1`; let reset adopt a non-stale generation; let observe return false; let advance do nothing; let frame return a detached safe dictionary with that generation, empty arrays/dictionaries, `busy: false`, `loop_phase: 0.0`. No preload or scene dependency is needed.

That scaffold lets the independent tester establish assertion failures for missing announcement, ownership, finite-cue and outcome behavior without import/runtime errors. Missing file, parse failure, incorrect method arity or unsafe initial frame is **setup failure**, exit 2, not evidence of behavioral RED. The tests dynamically load the new component only after checking this boundary. Do not count unrelated model errors as presentation RED.

## Tests authored in this invocation

- `games/borrowed-turns/tests/shadow_fixtures.gd`: controlled fixtures with explicit ability/HP/positions/budgets, independent of production tuning.
- `games/borrowed-turns/tests/shadow_presentation_run.gd`: controller tests using the current real model's two-argument `configure(fixture, "R2")`, confirmed snapshots and ordered events. It never loads the game scene or a production fixture.

Command after scaffold setup:

`godot --headless --path games/borrowed-turns --script res://tests/shadow_presentation_run.gd`

Coverage: current shove announcements, detached ownership facts, one-occurrence cancellation, fresh announcement coexisting with held old capture, release origin/target/full footprint, deadline backlash then enemy resolve, successful replacement ordering, source-death/out-of-reach failure, lethal no-acquisition with full footprint, stored source death, unchanged-invalid-command stale events, reset cancellation, old/future generation rejection, deep output/input isolation, deterministic time and finite completion despite persistent loops. The generous 60-second advancement is a stuck-completion probe, not a proposed animation duration. Tests assert model-provided footprints, not a second implementation of their geometry or hardcoded paper drawing coordinates.

Exit 0 means these controller behaviors passed, exit 1 means assertion RED/failure, exit 2 means scaffold/setup is missing. This does not establish visual appeal or runtime acceptance. No behavior test run is claimed in this brief; the separate independent tester owns the RED result.

## Subsequent implementation ownership and evidence

After assertion RED, the authorized implementation lane can own new controller/primitive-renderer files under `ui/`, narrowly update `board.gd` for rendering layers and existing coordinate transforms, and update `encounter_ui.gd` for plain/paper selection, transition handoff, finite completion and restart cancellation. It can update real UI integration smoke and README/run instructions under the later explicit assignment. Keep model/rules/content, immutable art notes, archives and completed technical gate behavior outside that lane unless separately assigned. Do not replace the verified rendered-smoke completion gate with a fixed sleep to accommodate animation.

Use separately launchable plain and paper presentations of the same fixture; do not add an alternate set of gameplay controls. Integration checks must drive the actual scene in both presentations, compare assessments/committed state/event history for identical commands, verify confirmation does not double-submit during finite feedback, and verify restart/terminal/reset behavior. Controller tests alone cannot establish these runtime contracts.

Evidence should include: a short capture → hold → release recording; a backlash/reannounce recording including the source fresh while the old shadow is held; representative paused frames for overlapping threats, replacement failure, legal lethal discharge and restart recovery. Capture primary 1280 × 800 and minimum 1024 × 720 views, using the actual gameplay scale. Check dimensions and label any SubViewport/injected-input evidence honestly; native physical input, compositor resize and HiDPI are separate checks or explicit skips. Do not add another concept-image round.

Ask Ronald separately whether he likes looking at it, whether it invites play, whether he understands ownership/danger, and whether capture/release/backlash feels satisfying. Keep the plain baseline available and reverse exposure order where practical, recognizing learning cannot be reset and one person's repeated sessions are not independent player samples. After his reaction, keep, revise or reject the pilot; do not automatically graduate it to production style or close FY3 on technical success alone.
