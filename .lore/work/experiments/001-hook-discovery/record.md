---
title: "Experiment 001: initial hook discovery"
date: 2026-11-15
status: draft
tags: [game-design, experiment, hook-discovery]
related: [.lore/work/intents/player-brief.md, .lore/work/research/game-hooks-and-player-promises.md]
---

# Experiment 001: initial hook discovery

## Inputs and provenance

- **ID and stage:** `001-hook-discovery`; first playable Borrowed Turns comparison implemented and functionally verified, checkpointed at `fd8e91d`. Initial human design feedback produced an agreed new capture direction in [revision 02](design-revision-02.md); that revision is not implemented. Structured enjoyment/replay evidence is still pending. The original discovery proposals below are preserved as history.
- **Request:** Ronald approved recording the player brief, defining the discovery skill and experiment template, and using them to propose first directions. No full game design yet.
- **Input snapshot:** `inputs/` preserves the brief, instructions, foundation notes, research synthesis, both skills, and template used for this discovery. `inputs/manifest.json` records source paths and SHA-256 hashes. Later revisions must not overwrite these inputs.
- **Agent:** Orchestrator, OpenAI `gpt-6.1-sol`. Prior source research and artifact-convention checks used the explorer; its configured model identity is not recorded here.
- **User decisions:** Ronald alone is the audience. Godot required; Blender available. Short complete runs, consequential choices, and unlocks with genuine new possibilities are the agreed direction. Increased power is not required. His fighter/monk example is explicitly excluded as a proposal.
- **AI assumptions:** Three directions are enough for this initial discussion; flat 2D placeholder prototypes are plausible cheap probes, not a chosen final visual style or platform. Proposed completion structures below are not settled specifications.
- **Tool checks:** `/usr/bin/godot`, version `4.7.2.stable.arch_linux.ed1daf0bf`; `/usr/bin/blender`, version `5.2.2 LTS`. `command -v godot`, `command -v blender`, `godot --version`, and `blender --version` returned exit 0. Runtime, rendering, export, and asset pipelines have not been tested.
- **Human contributions:** Ronald supplied preferences, examples, unlock standards, and tools. The original three concepts below were AI proposals. Ronald subsequently selected B, challenged its capture limits and unlock depth, supplied the artifact/hunted story seed, excluded a card-game approach, and agreed to the encounter baseline in the appended design record. These contributions do not establish originality.

## Discovery: three different promises

These are alternative directions, not the six versions required after choosing a mechanic. Working titles are descriptive, not branding decisions.

### A. Chain Workshop

- **Promise:** Build a small combat system whose parts interact in surprising ways, then watch your choices produce the action.
- **Anchor and hook:** A compact arena run, but upgrades connect events into a visible chain: an evasion can trigger a pulse; the pulse can mark enemies; a marked enemy's defeat can return an evasion charge. The player authors relationships rather than only collecting bonuses.
- **Candidate mechanic:** Connect a limited set of action triggers and effects between waves, then move and evade while the resulting chain executes. Costs and trigger limits prevent infinite loops. Choosing one link displaces another.
- **Run and unlock:** Clear a bounded sequence of waves and a final encounter. A potential unlock is an echo node that stores one event and releases it on a later chosen action, making timing part of a previously immediate chain. This adds a new kind of construction, not a promised power increase.
- **Risk and counterevidence:** Combat may become a spectator exercise or an unreadable effects storm. The hypothesis weakens if Ronald cannot explain how a changed link affected play, or if editing links feels like administration rather than anticipation.
- **Cheapest probe, not run:** A fixed arena, a few triggers/effects, and two small hand-authored chains. Test whether swapping one link changes movement decisions in an understandable way before building progression or random content.

### B. Borrowed Turns

- **Promise:** Win a compact tactical puzzle by stealing the enemy's plan and turning it against them.
- **Anchor and hook:** Turn-based encounters with visible enemy intentions. The player can capture a telegraphed action, preventing its original execution, then spend the stored action with a different origin or target on a later turn.
- **Candidate mechanic:** Choose which enemy action to capture, when to release it, and what to leave unresolved while the limited storage slot is occupied. Capture opportunities and enemies still create time pressure.
- **Run and unlock:** Complete a short sequence of encounters and an exit defense. A potential unlock is a relay that passes a released action through an occupied tile, creating a second origin to reason about. Its value must be new positioning decisions rather than a free second hit.
- **Risk and counterevidence:** Capturing the obvious strongest attack could trivialize every turn. The hypothesis weakens if one capture policy consistently removes interesting decisions, or if resolving the altered plan is too cumbersome to follow.
- **Cheapest probe, not run:** One board, two enemy intentions, one capture slot, and a known objective. Ask whether redirecting an intention creates a satisfying decision that ordinary attack selection does not.

### C. Rule Expedition

- **Promise:** Solve connected rooms by choosing which laws govern the expedition, then live with the consequences of those choices.
- **Anchor and hook:** A graphical logic-puzzle run in which clearing a room lets the player take one of its rules into later rooms. Rules have explicit effects such as “doors stay open after their switch is released”; limited rule slots force replacements.
- **Candidate mechanic:** Choose a rule to retain or replace, inspect its consequences, and solve the next small room under that evolving ruleset. This is not free-form text parsing: use a bounded catalog of explicit interactions.
- **Run and unlock:** Reach the exit after several linked rooms. A potential unlock is a rule inverter that applies the opposite of one carried rule in a selected region, opening new solutions and conflicts rather than simply easing every puzzle.
- **Risk and counterevidence:** Rules may make puzzles trivial or unsolvable, and interactions may be difficult to communicate. The hypothesis weakens if interesting choices require excessive rule reading or if selecting a rule mostly predicts an arbitrary future trap.
- **Cheapest probe, not run:** Two manually authored rooms, two carryable rules, and reset access. Check whether choosing what to carry creates a satisfying consequence in the second room; defer procedural room generation.

## Adjacent experiences and research limits

Direct official descriptions were accessed on 2026-11-15. These establish overlap, not originality or proof that Ronald will enjoy the proposals.

- [Noita](https://noitagame.com/) describes crafted spells and manipulating the world through magic. **A** overlaps in player-constructed interactions; its proposed emphasis is a small explicit event graph rather than a physically simulated world. The source does not establish that event chains are unique or provide an exhaustive comparison of spell-building games.
- [Into the Breach, official Steam listing](https://store.steampowered.com/app/590380/Into_the_Breach/) describes telegraphed enemy attacks and counterplanning. **B** shares that legibility; capturing and later spending an enemy action is the proposed distinction to investigate. The developer site returned HTTP 403, so the publisher-controlled store description was used instead.
- [Baba Is You](https://hempuli.com/baba/) describes rules as manipulable physical objects. **C** shares rule manipulation; carrying a bounded selection between rooms is the proposed emphasis instead of assuming its full spatial word-rule system. Other games may already explore similar progression.
- Broad web search hit the provider's daily quota. These are scoped direct-source comparisons, not an exhaustive search for the closest possible precedents. More targeted comparisons remain open after selecting a direction.

## Selection and handoff

**AI recommendation: B, Borrowed Turns.** It offers a tightly bounded decision, visible consequences, and controlled board states for diagnostics. This is a feasibility/information-value judgment, not evidence that it is the most enjoyable or novel. A is the closest to action/build experimentation; C most directly probes the logic-puzzle side of the brief.

**Human selection: B, Borrowed Turns.** Ronald accepted “Steal the enemy's plan, then make it do something they never intended” as the hook. See [the encounter and capture record](capture-bargains.md) for subsequent agreements and the six proposed alternatives. He subsequently authorized starting the build with minimal further input, leaving provisional implementation details to the agents. No human-play result exists.

Carry the selected promise and mechanic into `explore-mechanic`. Set executable rules, comparison criteria, and stopping conditions before collecting candidate results. Target platform/input and exact run length remain open where not settled by the encounter baseline.

## Comparison plan, builds, sessions, and findings

- **Plan:** `capture-bargains.md` retains the original hypotheses; `executable-rules.md` records provisional implementation rules. Mechanical correctness and reachability were checked; human comparison thresholds remain provisional rather than invented after results.
- **Six alternatives:** V1–V6 are implemented and accessible. No variant was excluded. Passing automated checks does not establish enjoyable choices.
- **Build/replay manifest:** See [source replay package](builds/PACKAGE.md), source hashes, archived project, and copied evidence. This is a source project, not an exported binary. No RNG or persistent progression is used; reset restores the configured fixture and preview mode.
- **Human sessions:** Not run. No enjoyment scores, desire-to-continue reports, voluntary replay, or unlock-payoff evidence exists.
- **Revision log:** Initial proposals preserved above; subsequent human selection, story contribution, encounter baseline, and AI-proposed capture alternatives are in `capture-bargains.md`. The original input snapshots remain unchanged.
- **Game outcome:** Human enjoyment, anticipation/payoff, and voluntary replay remain unknown. Both capture and no-capture strategies can escape this fixture in all variants.
- **Method outcome:** The procedure produced attributable proposals, six implemented bargains, a verified correction, and a preserved source/evidence package. Native OS input verification was blocked by reliable focus control. No comparative efficiency or general capability claim is established.

## Repeatability handoff

- **Replay:** Follow `builds/PACKAGE.md`. Archive extraction, all 20 source-file hashes, exact archive membership, and deterministic archive regeneration were verified. The archived source was not separately played after extraction; functional evidence applies to matching source in the working project. There are no save files or random seeds to restore in this fixture.
- **Repeat discovery:** Create a fresh `.lore/work/experiments/<new-id>/record.md` from the template, choose whether to reuse the snapshotted inputs or current revisions, record that choice, and invoke `discover-game-hook`. Do not overwrite this experiment or silently inherit its recommendation.
- **Limits:** Fresh AI proposals may differ. Resetting a future game cannot erase Ronald's exposure to its ideas or mechanics. Repeated sessions do not add independent participants.
- **Related Beads:** `mind-garage-pxe` records the procedure/documentation work, not authorization to build a game.

## First playable implementation coordination

Ronald asked whether any further input was needed before building, emphasizing autonomous progress. The agreed scope is six independently selectable Godot capture variants, common encounter fixtures, reset/replay, an optional shared Invert preview, and evidence-backed diagnostics. No full progression tree, generated art, dependency installation, external service, or unsolicited telemetry is included.

- Working branch: `experiment/borrowed-turns-prototype`; Beads feature `mind-garage-bo0`. Existing uncommitted documentation is preserved. No commit or remote sync is implied.
- Executable provisional decisions and model contract: [executable-rules.md](executable-rules.md). Interface direction: `interface-brief.md` when delivered.
- Implementation ownership: fixer for mechanics and deterministic tests; designer for visual/interaction direction and native Godot UI. Their write scopes do not overlap.
- Evidence path: controlled test-owned fixtures exercise the actual model, followed by independent headless runs, UI/runtime smoke checks, and production encounter diagnostics. Test setup failures do not count as behavioral RED. No-capture escape traces are content diagnostics, not proof of enjoyment or a reason to hardcode production tuning into unit tests.
- Verification ownership: a separate read-only fixer runs tests and reports exact commands, exit statuses, and evidence. Oracle is selected for read-only correctness review, a subsequent refactoring assessment, and a separate engineering-quality assessment. Designer owns visual review. The orchestrator reconciles findings and records final evidence rather than implementing or testing code directly.
- RED evidence: the independent tester ran `/usr/bin/godot --headless --path games/borrowed-turns --script /tmp/opencode/borrowed-turns-focused-red.gd`, exit 1. The temporary harness preserves existing test definitions and invokes `test_actions_and_preview()`. It reported assertion failures for assessment, exact preview, and movement advancement, with no parse/import/setup/runtime errors. Session log: `/tmp/opencode/borrowed-turns-focused-red.log` (temporary local evidence, not a durable artifact). Production action behavior is now being implemented; this RED result does not establish GREEN or playability.
- Evidence boundary at the RED checkpoint: the minimal project/API scaffold and test scripts parsed; final mechanics, playable interface, encounter diagnostics, runtime input checks, and reviews were still unverified. UI and mechanics implementation used disjoint write scopes and the same finalized contract; integration validation waited for both writers.

### Independent first-build evidence and correction

Both writer lanes completed. Independent execution returned exit 0 for the full model suite (83 checks), headless UI smoke (151 checks), and rendered UI smoke (171 checks). All six direct variant launches with Invert also exited 0. Logs and exact commands are recorded in the final handoff below when correction verification completes; current local logs are under `/tmp/opencode/borrowed-turns-independent*`.

A diagnostic harness found legal escape routes both using capture and without capture in every variant on the same provisional production fixture. This establishes reachable completion, not meaningful capture choice or enjoyment. The first V5 diagnostic route was corrected because its author incorrectly assumed a canceled shove still occurred; that was a diagnostic-script error, not a product defect. Preserve this distinction in subsequent conclusions.

Native OS input could not be reliably verified with available focus control. Rendered smoke uses explicitly sized Godot SubViewports; it does not establish native resize or HiDPI acceptance. Compact scrolling of the second intention row is an accepted visual tradeoff because both enemies and all threat cells remain visible on the board.

Correctness and visual reviews independently found **BT-COR-001**: changing Push/Pull updated the command and board prediction but left ordered Preview text stale. A controlled regression then returned exit 1 with 181 checks and exactly two assertion failures, one per toggle direction. Log: `/tmp/opencode/borrowed-turns-invert-red.log`. The bounded correction refreshes ordered text after reassessment without changing gameplay rules. Independent verification passed 181 headless and 201 rendered UI checks, exit 0; a fresh focused correctness review marked BT-COR-001 resolved with no newly introduced material defect.

The subsequent read-only refactoring assessment recommended only **BT-REF-001**, an optional consolidation of preview-text refresh into the shared reassessment helper. Disposition: defer for this first stable playtest. Current paths are correct and covered by the new regression; consolidation becomes more valuable if additional reassessment callers are introduced. No broader restructuring was recommended.

Independent engineering-quality review found the implementation adequate for the first playable, with no material defect. It accepted the authoritative model/UI boundaries, fixture isolation, preview strategy, and bounded complexity. The optional preview cleanup remains deferred. The other recommendation, excluding generated Godot caches before checkpointing, was applied as a narrowly scoped root `.gitignore` rule. Before/after `git check-ignore -v` showed the cache change from unignored (exit 1) to ignored (exit 0); game sources and package identity were unchanged.

## First playable handoff

From the repository root:

```bash
godot --path games/borrowed-turns
godot --path games/borrowed-turns -- --variant=V6 --invert
```

All variants are selectable without completing another. Choose an action, select its source/target, inspect the preview, then confirm. Reset/replay preserves the variant and preview configuration; variant switches start clean. [Game instructions](../../../../games/borrowed-turns/README.md) describe controls and limitations.

Durable source identity and replay instructions: [builds/PACKAGE.md](builds/PACKAGE.md). Archive SHA-256: `83278bd8a4b0bb5a989818c9e63d858d67aae8da63cfc29d707b8896617d17ab`. [Copied evidence](evidence/) retains exact logs, diagnostic harnesses, the corrected screenshot, and integrity hashes. The source package does not include user telemetry or a compiled export.

| Evidence | Command from repository root | Exit and result |
| --- | --- | --- |
| Model correctness | `godot --headless --path games/borrowed-turns --script res://tests/run.gd` | 0; 83 checks, 0 failures |
| Corrected UI | `godot --headless --path games/borrowed-turns --script res://ui/smoke.gd` | 0; 181 checks, 0 failures |
| Rendered corrected UI | `godot --path games/borrowed-turns --script res://ui/smoke.gd -- --capture-dir=/tmp/opencode/borrowed-turns-corrected` | 0; 201 checks, 0 failures |
| Direct launch | `godot --headless --path games/borrowed-turns --quit-after 3 -- --variant=Vn --invert`, each V1–V6 | 0 for every variant |

The tester used `/usr/bin/godot`, version `4.7.2.stable.arch_linux.ed1daf0bf`. Unchanged model/launch evidence was reused after the UI-only correction rather than rerunning unrelated checks. Correctness review and focused correction review found no unresolved material defect; engineering-quality review accepted the first playable. Fixed-size rendered viewports and injected controls do not establish native OS mouse/keyboard, window-manager resizing, or HiDPI acceptance.

Next evidence must come from Ronald's play. This first fixture tests understandability and the feel of the capture bargains; it is not a finished roguelite, a tested unlock path, or a demonstration that capture is necessary or rewarding. Keep reported enjoyment, desire for another run, voluntary replay, and reactions to Invert separate. Any later encounter tuning or progression work needs its own recorded hypothesis and comparison, not a retrospective claim that passing these checks found the fun.

## Post-prototype design feedback: revision 02

Ronald challenged whether the original six variants offered enough diversity, distinguishing useful common constraints/tuning from distinct mechanics. He supplied a revised shared direction: separate interleavable movement/action budgets, unlimited free capture, action-cost release, ability-derived release range, forced release, ability-specific replacement/expiry backlash, and no discard. He explicitly chose backlash rather than a per-turn capture cap as the starting restriction.

See [the full decision record](design-revision-02.md) for the human/AI contribution sequence, rejected cap proposal, rationale, open timing/geometry details, and proposed evidence. These are part of the experiment's method outcome: substantial human design judgment was needed after the first AI-led exploration. No claim of improved enjoyment is supported yet. The running game, original executable rules, input snapshots, and packaged first-build evidence remain unchanged.
