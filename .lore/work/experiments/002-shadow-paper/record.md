---
title: "Experiment 002: theatrical action-shadow pilot"
date: 2026-11-15
status: draft
tags: [game-design, visual-experiment, shadow-paper, player-feedback]
related: [.lore/work/experiments/001-hook-discovery/presentation-intent.md, .lore/work/design/borrowed-turns-art/borrowed-turns-shadow-paper-brief.md]
---

# Experiment 002: theatrical action-shadow pilot

## Question and boundary

Does a recognizable animated action-shadow make stealing, holding, releasing and enduring an existing ability more appealing, understandable and satisfying than the plain prototype?

This is a reversible one-ability runtime visual experiment, not final art direction, production assets or new mechanics. Ronald authorized autonomous progress while requiring the technical loose ends to be finished first and fy3 to remain open for his actual visual reaction. The later mechanics phase must not start before that review.

## Inputs and provenance

- Game: *Borrowed Turns*. *Mind Garage* is the broader experiment, not the game title.
- Bead: `mind-garage-fy3`. Subsequent mechanics discussion: `mind-garage-7am`, blocked on fy3.
- Technical prerequisites completed and checkpointed first: completion gate `mind-garage-84b` at `29cd5ef`; permanent off-axis regression `mind-garage-2nx` at `ba3ab7a`.
- Plain source baseline: immutable commit `ba3ab7a`. Existing engine, encounter, authoritative rules, budgets and controls are the comparison foundation.
- User-supplied art exploration: commit `4727f30`, paths under `.lore/work/design/borrowed-turns-art/`. The webp is a mood/construction reference, not a gameplay or spatial specification.
- User clarification: `.lore/work/experiments/001-hook-discovery/presentation-intent.md`, first recorded at `66f90e8`. Art notes are intent/musings; shadow placement can be explored. Capturing removes one announced occurrence, and a surviving/eligible enemy gets its action-shadow back when it announces again. Invert was explicitly removed and must not return by inertia.
- Agent/model: Orchestrator `openai/gpt-6.1-sol`; retained designer owns visual decisions and implementation, a separate fixer owns runtime evidence, and fresh oracle review owns technical correctness and engineering quality.

These immutable source references preserve the inputs without overwriting supplied notes or pretending earlier code did not exist. Any candidate source and evidence identities will be recorded after validation.

## Working pilot, not permanent requirements

The designer recommends the existing **shove**. Keep the initial comparison's rules and geometry unchanged by choice, so presentation can be investigated without a simultaneous mechanics revision. That does not settle future debates about shadow placement.

Use provisional flat paper figures for the ordinary protagonist and shoving pursuer, plus a jointed arm/open-palm action-shadow. The provisional artifact token remains; do not silently declare a lantern to be the artifact. Other ability kinds may retain plain treatment in this one-ability slice. No ordinary cast shadows are proposed for the pilot, following the theatrical intent rather than the reference image's physical lighting.

The action-shadow should remain recognizable through announcement, capture transfer, framed held state, deliberate release and uncontrolled backlash. Fresh source announcement can coexist with the player's previously captured motif. Bodies, source identifiers, health, threatened cells, held deadline, outcome previews and input affordances must remain understandable in paused frames and overlapping-threat conditions.

The implementation brief and component contract will be written by the designer in `pilot-brief.md`. No concept generation, finished artwork, Blender model, downloaded dependency, external service, audio production or final asset pipeline is included. Runtime prototype authorization does not imply acceptance of the resulting appearance.

## Comparison and predictions, before results

Hold the encounter, rules, abilities, available information and action sequence constant. Provide separately accessible plain and pilot presentations of the same game. Changing presentation must not spend points, reset or otherwise mutate the model. Preserve the immutable plain build as well as the in-candidate comparison mode.

Expected useful signals:

- The source and the held ability remain identifiable before and after transfer.
- The same gesture reads as the stolen action when released, not an unrelated spell projectile.
- Backlash remains visibly distinct and includes the player's risk, not just an attractive effect.
- Ronald finds the result more inviting or satisfying without losing tactical understanding.

Counterevidence includes obscured threat cells, permanently-disabled-enemy implications, confusion between held and fresh announcements, identical release/backlash readings, stale animation after reset, or motion that feels like delay rather than feedback. Visual inspection and automated checks can expose some failures but cannot establish Ronald's taste or enjoyment.

Ask separately about visual appeal, ownership/tactical clarity and action satisfaction. Desire to replay remains separate. One player's learned familiarity and exposure order limit causal claims; this bundled visual pass cannot identify the individual contribution of every shape or motion.

## Verification path and ownership

The designer first defines and tests a small presentation-state contract. A loadable empty-state setup, if needed, must precede independent behavioral RED; missing imports are not valid RED. Presentation consumes current snapshots and ordered confirmed events, never a second rules simulation. Finite transition completion must remain separate from persistent idle/held loops.

A separate read-only tester will verify event ownership, immutable inputs, capture/hold/release/backlash/reannouncement, failed/lethal replacement, reset/stale-generation isolation, plain/pilot state equality, and unchanged model tests. Actual rendered checks use the completed smoke gate, with fresh output, a final summary and terminal capture rather than process status alone.

Capture actual gameplay-scale stills and short motion evidence, including minimum-size/paused frames and held-old-shadow plus fresh-source-shadow. Note any missing motion tooling or native-input limitations rather than inventing success. Inspect the actual artifact, not just a render-exit status. Technical correctness, visual critique and Ronald's runtime acceptance remain separate.

## Current state

The visual phase was claimed only after both prerequisite checkpoints. The designer supplied [the pilot brief](pilot-brief.md), controlled model-backed presentation tests, and then a separate loadable empty interface. Independent execution of `godot --headless --path games/borrowed-turns --script res://tests/shadow_presentation_run.gd` established behavioral RED: exit 1, 196 checks and 49 assertion failures for absent ownership, cue, footprint and time behavior, without setup, arity or runtime errors. Local log: `/tmp/opencode/borrowed-turns-fy3-controller-red.log`.

Controller, primitive renderer and narrow UI integration were subsequently implemented against that contract. Existing model/content, completed technical gate and supplied art remained outside the writer's scope. The results below distinguish functional execution, visual credibility and unresolved human acceptance. No player preference or satisfaction finding is asserted.

FY3 must remain open until Ronald can react to the actual pilot and choose iterate, compare, or reject. The agent may complete implementation and technical validation autonomously, but must not close this human-review gate or start `mind-garage-7am` on the strength of screenshots or tests alone.

## Threat to validity: a primitive treatment may not represent the direction

Before seeing the candidate, Ronald allowed work to continue but expressed doubt based on earlier primitive-based experiments producing visually inexplicable results that could not fairly be judged for visual quality. This is material input about the experiment, not a request for more technical checks or authorization to generate finished assets.

The candidate must first be visually judgeable: recognizable paper figures, a coherent and identifiable pushing-shadow motif, understandable ownership through its lifecycle, and adequate staging/readability at actual gameplay scale. Technical tests cannot establish these qualities. An independent visual credibility review will assess that boundary before the candidate is treated as evidence about art appeal.

If the primitive implementation cannot represent the intended treatment after a bounded refinement, report that method/implementation limit with the actual evidence; do not conclude the shadow-paper direction failed or ask Ronald to evaluate an unintelligible placeholder as if it were representative. Conversely, a credible candidate that Ronald dislikes supplies legitimate negative feedback; do not automatically blame every unfavorable reaction on the primitives. A one-ability slice still cannot establish the appeal of a finished environment, full cast or production material treatment.

## Candidate results: technical function and visual credibility are separate

The designer completed one implementation/refinement batch and supplied plain/paper views, lifecycle stills and two short runtime clips. Independent functional execution passed controller 193/0, unchanged model 285/0, headless UI 280/0, and the real rendered completion gate 309/0. Plain and paper startup both exited 0; the retired Invert flag still exits 2. These results establish the exercised code behavior, not visual appeal. The controller's prior RED was 196 checks with 49 failures; no pre-RED source hash is available for an independent byte-level comparison of its test file.

An additional real-model diagnostic verified an event-time resolve anchor after backlash moved the announcing shover from `[3,3]` to `[4,3]`. It passed, but that exact sequence is not an explicit permanent controller regression. The tested shared model/content/completion gate and original art remain unchanged from the plain baseline.

The independent creative review classified the candidate as **usable for ownership, legibility and motion inspection, but not representative enough to fairly test theatrical shadow-paper aesthetic appeal**. Recognizable coats, an identifiable open hand and lifecycle continuity are useful, rather than meaningless polygons. However, the tiny figures/gestures remain subordinate to the text-heavy interface; the held motif becomes congested near the protagonist and fresh source; shadow identity reads more as interface iconography than a coherent construction language; and backlash still relies heavily on existing warnings.

These are concrete limits of this execution and staging, not proof that primitives necessarily cannot work or that the intended art direction is wrong. The reviewer recommended showing the limited pilot honestly rather than requiring another polish cycle before Ronald can react. It inspected actual stills/contact sheets, not the MP4s, so its assessment does not establish continuous-motion smoothness or satisfaction.

Consequently the broader visual-appeal question remains unanswered. No additional art route or gameplay change is being undertaken automatically. Technical correctness/quality review and frozen-source capture provenance checks continue before checkpointing this candidate. FY3 remains open; 7am remains blocked.

## Technical review: bounded corrections required

Fresh correctness review identified two material presentation edge cases despite the initial GREEN suites:

- **FY3-C01:** the renderer used final run loss to collapse a backlash at the player. An earlier nonlethal backlash can damage/displace enemies before a later attack kills the player; the earlier cue must reflect its own resolution rather than the eventual outcome.
- **FY3-C02:** committed footprint markings used the old 0.18-second pulse, shorter than the finite shadow cues. Consumed storage then leaves no settled backlash markings. The active cue must retain its own copied model cells throughout its lifetime, without showing all later queued effects early. Paused capture advancement also needs to advance the relevant presentation clocks consistently rather than mask pulse expiry.

The designer authored controlled regressions, then separately extracted behavior-preserving rendering decision seams. Independent execution established behavioral RED: `tests/shadow_rendering_run.gd` exited 1 with 73 checks and six assertion failures, without setup/import/runtime errors. One assertion exposed C01; five exposed C02 across active backlash and subsequent resolution cues. Log: `/tmp/opencode/borrowed-turns-fy3-correction-red.log`.

The bounded production correction attributes collapse to the backlash's own ordered outcome, draws the active cue's copied tactical footprint until completion, and samples capture evidence with normal scene processing rather than advancing only one presentation clock. Author checks report rendering regression 74/0 and controller 193/0; independent revalidation is underway. These fixes concern truthful presentation and evidence, not another artistic refinement or an attempt to satisfy the unmet appeal goal. The shared model/content and completion gate remain protected.

A separately source-hashed recapture of the pre-correction working candidate completed 17 stills and two motion sequences with unchanged before/after source membership/hashes. It has explicit provenance but is not the final corrected candidate; preserve that distinction. Corrected source and affected media will require revalidation after the fixes. The independent aesthetic assessment above describes the unchanged overall staging/construction, not a technical acceptance of the two defective edge cases.

Independent correction execution passed rendering 74/0, controller 193/0, model 285/0, headless UI 280/0 and rendered gate 309/0. Fresh review accepted C01, the original C02 failure and capture-clock correction, but identified **FY3-C03**: selecting shove cue footprints suppresses all legacy committed effects, including bolt/burst events that have no shove animation. Capturing a shove while replacing a held bolt can therefore hide the bolt backlash. Mixed enemy resolution has the same boundary risk. Controlled mixed-transition coverage precedes a second bounded correction; the 74 passing assertions remain relevant but did not cover this interaction.

The packaged evidence currently preserves the C01/C02-corrected snapshot, source manifest SHA-256 `d8bd7423664a68db01a4e00b8f3ea0c9a477911a83ab38e94f746848f7c68355`. It is not final accepted source and must not be silently relabeled after C03 changes. The package is about 5.8 MB, retaining stills, clips, contact sheets, exact logs and a source archive while explicitly omitting reproducible raw frames.

C03 followed a second test-first correction: independent RED exited 1 with 124 checks and six assertion failures, with C01/C02 still passing. Test/fixture hashes were recorded before RED and verified unchanged through GREEN. The controller now sequences all model-authored ray/area feedback as finite tactical cues; only shove receives the hand animation. Independent GREEN passed rendering 149/0, controller 193/0, model 285/0, headless UI 280/0 and rendered gate 309/0. The increased rendering count reflects checks reached along the now-complete mixed timeline, not a changed frozen test. Plain/paper startup exited 0 and retired Invert exited 2. Logs: `/tmp/opencode/borrowed-turns-fy3-c03-green-*.log`.

A fresh focused correctness review accepted C03 and preserved C01/C02 acceptance, finding no new material correctness defect. The subsequent refactoring assessment suggested projecting backlash-local death into its cue rather than interpreting event boundaries in the renderer. This is nonblocking: the current small helper is specifically tested, and changing the cue contract adds another validation cycle without a new consumer. Defer that optional extraction. Separate independent engineering-quality review accepted the bounded implementation, with no material blocker and no measured performance issue. No artistic acceptance is implied.

## Evidence storage clarification

Ronald clarified that regenerable runtime/test artifacts must not be committed. The generated FY3 package was moved byte-for-byte into gitignored `.lore/local/experiments/002-shadow-paper/evidence/`; the tracked [reproduction guide](evidence/README.md) now documents commands rather than depending on those files. The local package is explicitly the pre-C03 snapshot. Final discussion captures also remain local or temporary, not a tracked replay archive. Source, tests, configuration, results and interpretation remain documentation/source-control material. Earlier Git history is not rewritten by this policy.

After final correctness and engineering-quality acceptance, the independent tester captured the stable C03-corrected source into `/tmp/opencode/borrowed-turns-fy3-final`: 17 stills, two motion sequences, zero capture failures. Source manifest SHA-256 `48bf999f4f841299ad6d618de52eea5570d083ff3f7b191a54c7c237832e2f06` identifies 37 files, with matching before/after hashes and membership. Both 1280×800, 30 fps clips decoded successfully: normal 137 frames (4.566667 seconds), backlash 121 frames (4.033333 seconds). The source/artifact manifests and exact provenance remain temporary discussion evidence, not committed artifacts. The reproduction guide does not depend on their presence.

## Human review and revised visual hypothesis

Ronald found the primitive pilot interesting but explicitly said it did not demonstrate art direction. The agent agreed: this implementation cannot answer the intended aesthetic question. This is an experiment-method limitation, not rejection of the reference direction.

After approving a single look-frame description and explicitly authorizing one image, Ronald reviewed the generated candidate. The image was verified and kept locally at `.lore/local/experiments/002-shadow-paper/look-frame/candidate.png`; it drifted into side-view heroic figures, ordinary grounding shadows and a claw-like action. Ronald identified the original supplied `lantern-hero-in-the-shadow-forest.webp` as still closest to his expected style. He specifically liked the surrounding stage frame, standee-like figures, elaborate background shadow puppets distinct from the figures, and the lantern. Lantern appreciation does not establish a gameplay mechanic.

Ronald proposed separating precise board action-telegraphs from cinematic background puppet performances. The agreed working hypothesis is that puppets **rehearse** currently announced threats while the player decides: “If you do nothing this is what will happen to you.” This is conditional warning, not advancing game time or a simulation of every future outcome. The agreed textual sequence is announcement/rehearsal, capture/ownership handoff, then release/committed performance. Capture still steals one announcement; fresh enemy rehearsal can return independently of a held action.

Ronald separately approved and authorized one empty stage study using the original image as reference. The generated stage candidate at `.lore/local/experiments/002-shadow-paper/look-frame/stage-candidate.png` decoded as a 1672×941 RGB PNG, SHA-256 `848fb3f8ac27da816e5119960a42c1fc77e90b3858e6f199f5fb6393bbc828df`. He said it “looks great.” This approves its visual direction, not character designs, puppet readability, extracted production layers or runtime acceptance.

The next proposed consumer is Godot 2D with a perspective-projected logical board, upright depth-ordered standees and separate backdrop puppets. Backdrop, floor and foreground are aligned visual families, not independently redesigned compositions. The floor source is top-down and ungridded; runtime grid, telegraphs, placements and targeting must share its board mapping. A real 3D plane is not currently needed; camera movement or physical lighting/depth requirements could change that decision. Ronald approved starting here and explicitly welcomed fast iteration and pivots.

Current bounded work starts with the floor component's production brief, not a large asset batch. A removable flat background may be useful for later isolated components; painted checkerboards are not alpha transparency. No layer extraction, transparency processing or runtime integration is implied by liking a concept. Generated candidates and processing evidence remain local.

## Approved stage sources and integration authorization

Ronald approved each production source separately: floor (“I think its fine”), backdrop (“we can keep it”), then foreground (“looks great”) after seeing the foreground over the approved backdrop. The originals were promoted unchanged into `games/borrowed-turns/assets/stage/`, with byte comparisons, SHA-256 verification and successful reopening. These are source artwork, not regenerable gameplay/test output; they belong in source control. Their [asset README](../../../../games/borrowed-turns/assets/stage/README.md) records delivery, approvals and provenance.

- `floor-paper.png`: opaque 1254×1254 PNG, below the requested 2048×2048; disclosed before approval.
- `backdrop-paper.png`: opaque 1672×941 PNG; heavier arch, lower-corner foliage and warm gradient disclosed before approval.
- `foreground-paper.png`: 1672×941 RGBA PNG. Although removable green was requested, the tool supplied actual alpha. Light/dark edge and registered-backdrop inspection found no obvious green contamination or broad matte halo. No removal or normalization was performed; the original partial-alpha pixels remain.

Each component required one authorized image-generation call. No runtime screenshot, inspection composite or raw output is promoted as source artwork. No additional cast or puppet artwork is authorized.

After choosing to finish the stage artwork before changing the game view, Ronald explicitly selected **Integrate the stage** once all three sources were approved. This authorizes a bounded integration into the existing encounter: layered stage, perspective-projected paper cells, runtime board dimensions, stable cell variation and shared targeting/telegraph projection. Preserve the plain view and current mechanics. The next evidence path combines controlled mapping checks, existing behavior regressions, actual rendered completion and Ronald's runtime visual reaction. Artwork approval is not runtime acceptance; FY3 remains open and 7am remains blocked.

### Integration working outline and RED

The designer's [integration contract](../../design/borrowed-turns-art/stage-components-brief.md#stage-integration-outline-and-test-contract) adds an optional `stage` presentation while keeping `paper` as default and retaining `plain`. The stage gets full-width layout rather than being squeezed into the former board column. Exact details and ordered previews remain accessible over the upper backdrop; persistent status and controls stay outside the floor. Raising the floor's start moderately from the concept is an explicit tradeoff of puppet-screen area for targeting space, not an artwork edit.

The designer authored controlled projective mapping/material/actual-board tests and extended the existing UI smoke rather than cloning the full lifecycle matrix. A separate neutral setup supplied loadable helpers and behavior-preserving board seams. Independent RED then exited 1 with 403 projection checks/335 failures and 3 focused stage UI checks/1 failure for absent stage selection. Both started cleanly; missing imports or setup errors were not counted as RED.

Frozen test hashes were recorded before execution in `/tmp/opencode/borrowed-turns-stage-red-tests.sha256`. Logs are `/tmp/opencode/borrowed-turns-stage-red-projection.log` and `...-ui.log`. A separate production implementation pass follows. The independent tester owns subsequent mapping/behavior/render evidence; fresh oracle review owns correctness and engineering-quality assessment; the designer owns actual-runtime visual inspection. Tests cannot establish Ronald's visual acceptance.

### Integrated stage: initial GREEN and actual-scene critique

The separate production pass implemented the optional stage view and source-texture imports. Independent execution passed projection 405/0, focused stage UI 217/0, unchanged model 285/0, controller 193/0, rendering 149/0, full headless UI 512/0 and gated rendered UI 553/0 with terminal capture accepted. All exited 0. Plain/paper/stage startup exited 0; unknown presentation and retired Invert each exited 2 with explicit rejection. Frozen tests and approved PNG bytes remained unchanged. Logs: `/tmp/opencode/borrowed-turns-stage-green-*.log`.

The full gate captured actual production-content stage views at 1024×720 and 1600×900, separately named from controlled shove-preview/held fixtures. A temporary actual-scene interaction clip exercised injected capture controls, with committed state matching preview: 75 frames at 1024×720 and 30 fps, 2.5 seconds, full decode passed. The 56-file post-import source manifest matched before/after capture and includes source UID/import settings but excludes caches; manifest SHA-256 `255ce6be0f7ec5789821eca66d8bf13d49346826f28ae1d0b9b7e809b1879dad`. These remain temporary/local evidence, not committed output.

Independent creative critique now considers the actual stage a legitimate visual-review candidate, unlike the earlier primitive-only pilot: coherent paper materials, framing and depth are visible. It found no material foreground occlusion, preview-sheet floor coverage, conspicuous matte fringe or scenery depth-order defect in the inspected stills. It did find weak contrast for dark provisional hand silhouettes and held/selection strokes crowding some actor labels. Separate paper-piece character is subtle at minimum size and remains a taste question for Ronald rather than a reason for automatic asset replacement.

The reviewer recommended showing the current scene without a broad polish cycle. Its evidence was six stills, not motion or physical input. A larger actual-encounter capture was presented to Ronald with the limitations explicitly stated. Fresh technical correctness review is underway; technical GREEN is not runtime visual acceptance. Physical mouse/keyboard behavior, compositor-native resizing and HiDPI remain unverified. The eventual elaborate backdrop-puppet layer and finished standees remain outside this integration.

Fresh correctness review confirmed the actual shader and board consumers share the projection but found **STAGE-C01**: returning from stage with its Plans tab inactive reparents the details panel without restoring visibility. Stored-ability details and enemy-intention controls can disappear from plain/paper even though model equality tests pass. An existing later GREEN screenshot already shows history occupying the rail where those details should be, so this is observed counterevidence, not merely hypothetical risk. The designer is adding focused round-trip visibility coverage before a bounded correction. Do not call the integration complete on the initial GREEN results.

Independent STAGE-C01 RED passed setup and exited 1 with 304 focused stage checks/20 assertion failures. Returns from Preview and Recent events to each baseline lost visible/usable details and intention controls; active Plans supplied a passing control. Logs and frozen hashes: `/tmp/opencode/borrowed-turns-stage-c01-red.log` and `...-red-tests.sha256`. A separate production correction changed only the UI layout restoration: original visibility is now saved and restored along with parent/layout state. Author focused GREEN passed 304/0 with frozen tests unchanged; independent correction verification follows. This does not change artwork, projection or tactical rules.

Independent correction GREEN passed focused stage UI 304/0, full headless UI 599/0 and gated rendered UI 640/0 with terminal capture accepted. The exact six tab-return transitions are verified by actual visibility/geometry/scroll/control assertions. A later held-state screenshot also shows the rail restored, but follows fixture resets and is not direct image evidence for every transition. Do not overstate that image.

Only `encounter_ui.gd` and the intentionally extended smoke changed relative to the initial stage source snapshot. The corrected 56-file manifest matched before/after capture, SHA-256 `9eb93bb1a3941a0a97165f4d3c196444e150f259855effc16294074e72fc344d`. Frozen tests and source PNGs remained unchanged during verification. Prior projection/model/controller/rendering evidence was reused because those inputs and code did not change. Correction logs are `/tmp/opencode/borrowed-turns-stage-c01-green-*.log`; outputs remain local. Fresh correction review follows, not an automatic claim of completeness or human acceptance.

Fresh correction review accepted STAGE-C01 with no new material correctness risk in the changed scope. Mandatory refactoring assessment found one modest optional cleanup: consolidate consequence-color ownership in `_refresh()` instead of retaining two earlier overrides that it immediately supersedes. Defer this behavior-preserving cleanup before Ronald's review: current calls refresh synchronously, and the small maintenance saving does not justify another source/validation cycle now. No projection/material/renderer extraction was recommended. Separate engineering-quality assessment follows; no refinement or art-polish loop is automatically authorized.

Separate independent engineering-quality assessment accepted the integration with no material blocker. It found the shared-map architecture and per-cell renderer proportionate to the current encounter; no profiling establishes a performance claim. It supported deferring the small color-ownership cleanup. It also noted that the floor source currently imports without mipmaps while the renderer requests mipmap filtering: this is a sampling hypothesis to investigate if actual minification/resizing reveals shimmer, not an observed defect or permission to change approved art/import settings automatically.

The technical candidate is ready for Ronald's bounded runtime review, not closure of FY3. The current questions are whether the stage composition and grid feel right in play, whether separate paper pieces are distinct enough, and whether provisional feedback remains readable. Known contrast/crowding limits stay explicit. Source artwork and implementation may be checkpointed; screenshots, recordings, manifests, logs and caches remain local. The next mechanics bead remains blocked.
