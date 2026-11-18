# Mind Garage

A workspace for multiple experiments in AI-led game design. Each experiment explores a small, replayable game and the process used to find its fun.

**Mind Garage names the experimental effort, not a game.** Individual game prototypes have their own working titles; the selected first direction is currently called **Borrowed Turns**.

The shared research question is: **Can AI originate a central game mechanic and drive its refinement into something players enjoy and voluntarily return to?**

Human playtest feedback is part of that process. The question is not whether AI can build a game without human contact, or whether a clever prompt alone can establish that a design is novel and fun.

## Current prototype: Borrowed Turns, Switcher exploration

Survive an enemy's announced attack, borrow its ability, then turn it against the hunt. Normal play opens a **solo Switcher** fight in the accepted Stage presentation. **Switcher + B** is independently available in the encounter selector:

```bash
godot --path games/borrowed-turns
godot --path games/borrowed-turns -- --encounter=switcher-b
```

The candidate uses **3 shared AP per turn**: a cardinal step, arming Capture, or Shine costs 1 AP. Armed Capture acquires the next enemy attack that hits you **after its normal damage and effects**; it does not cancel danger. Shine repeatedly uses the held ability without consuming it. Holding has no expiry or backlash, but defeating its source removes the ability. The Switcher locks one cell, exchanges positions with its occupant, then deals damage. B retains its three-wide shove. Reaching zero AP does not advance time. See the [play instructions](games/borrowed-turns/README.md), [Switcher record](.lore/work/experiments/004-switcher/record.md) and [earlier active-fight record](.lore/work/experiments/003-active-opponents/record.md).

This is a mechanic prototype, not a finished roguelite or a validated progression system. Ronald reports the 5×5 armed-Capture/reusable-Shine fight at `744fca3` felt good, engaging and puzzle-like, but not particularly replayable as the same encounter. That is positive engagement evidence from one player, not run retention or a general enjoyment result. Normal launch now uses the accepted **7×7 Stage extent** from `8275a48`, without edge coordinate labels or smaller actors. Combat rules and stats are unchanged; layout acceptance is not a new balance claim. The [Curtain Call narrative direction](.lore/work/narrative/borrowed-turns/curtain-call-narrative-brief.md) supplies context, not an exhaustive mechanics specification.

The accepted A+B fight remains available with `--encounter=two-pursuers`; escape remains `--encounter=escape`. These are encounter choices, not old rules or display modes. Mechanical feasibility does not establish that the new opponent is fun.

The first six-variant prototype is preserved at source commit `fd8e91d`; it is not a parallel mode in the live game. Subsequent human feedback and the unlimited-capture/backlash direction are recorded in [design revision 02](.lore/work/experiments/001-hook-discovery/design-revision-02.md), with provisional [executable rules](.lore/work/experiments/001-hook-discovery/revision-02-executable-rules.md).

The separate [revision-02 replay guide](.lore/work/experiments/001-hook-discovery/builds/revision-02/README.md) identifies checkpoint `009311b` and its recorded test results without replacing the first-build record. It predates the subsequent Invert removal; historical features are not current requirements. Generated archives and raw output are local, not required checkout files.

### Accepted presentation baseline

The [action-shadow experiment](.lore/work/experiments/002-shadow-paper/record.md) records the earlier primitive pilot, concept exploration, accepted stage/standees/Director and source-driven wavefronts. Ronald accepted the resulting visuals as sufficient not to detract from gameplay; `mind-garage-fy3` is closed. That is not a finished-art or enjoyment claim.

```bash
godot --headless --editor --path games/borrowed-turns --import
godot --path games/borrowed-turns
```

Stage is the sole presentation. The accepted art and shared board projection are unchanged by the active-opponent revision. Runtime puppet textures ship in the game; necessary preparation artwork and recipes live under `assets-source/`. No local experiment history is needed to play. See the [stage instructions](games/borrowed-turns/README.md#theatre-stage).

The active-fight, Stage-capacity and Switcher checkpoints are complete. Ronald considers Switcher sufficient for now, with polish deferred. Current discussion `mind-garage-g9s` defines a configurable opponent-component library before implementation; multi-fight runs and progression remain deferred under `mind-garage-7am`.

## Shared foundations

All experiments start from the notes in [`.lore/work/notes/`](.lore/work/notes/):

- [AI game-design experiment](.lore/work/notes/ai-game-design-experiment.md) proposes the research method, evidence layers, and iteration protocol.
- [Can AI design a novel, fun game?](.lore/work/notes/ai-design-novel-fun.md) distinguishes evidence of AI-assisted development from unproven claims of autonomous invention or originality.
- [What makes games fun?](.lore/work/notes/what-makes-games-fun.md) summarizes selected research on agency, mastery, connection, absorption, and meaningful appreciation, including its limits.

These are starting points, not established experiment results or a universal recipe for fun. This workspace focuses on repeatable engagement without claiming that one-time or primarily meaningful experiences are lesser games.

## Multiple experiments, shared discipline

Each experiment should have its own identity, question, prototype, configuration, evidence, and run instructions. A result belongs to the game version, audience, and conditions tested, not automatically to every experiment here.

Before building a particular game, agree on:

- The proposed mechanic, what is claimed to be distinctive, and the intended players.
- Development scope, technical constraints, and how to run and reproduce the prototype.
- Correctness checks and mechanic-specific automated diagnostics.
- Necessary telemetry, consent, and playtest recruitment.
- Baseline and candidate comparison design, measurements, decision thresholds, and stopping criteria.

### Current audience and constraints

- **Audience of one:** Ronald is the initial intended player. The goal is to discover what he enjoys and voluntarily returns to, not establish market demand or general player preferences. Repeat sessions help investigate his experience but do not increase the number of independent players.
- **Engine:** Playable experiments must use Godot and be buildable with the tools available here. Check installed versions and capabilities when planning implementation.
- **Supporting tools:** Blender is available when useful. This does not require 3D or authorize asset creation by itself.
- **Still open:** Genre, desired player experience, 2D/3D, target platform/input, and telemetry approach remain experiment decisions.

The notes do not authorize a particular implementation. Start with a prototype small enough to revise repeatedly and choose techniques that fit these constraints.

## How we look for fun

Start with the [player brief](.lore/work/intents/player-brief.md), then use [`discover-game-hook`](.agents/skills/discover-game-hook/SKILL.md) to explore a few experience promises and select a direction. Hand its candidate mechanic to [`explore-mechanic`](.agents/skills/explore-mechanic/SKILL.md) for six alternative versions with independently playable survivors. A promising pitch is not evidence that playing it is fun.

Keep a separate record per experiment at `.lore/work/experiments/<experiment-id>/record.md`, using the [experiment template](.agents/skills/discover-game-hook/templates/experiment-record.md). Record source/input/procedure versions, configuration, seeds and replay commands so we can repeat a comparison. Neither resets player learning or guarantees identical AI proposals.

Commit source, tests and substantive documentation, not regenerable evidence. Screenshots, recordings, raw logs, generated manifests and build/source archives belong under gitignored `.lore/local/` if needed for discussion. Document results and how to reproduce them without requiring those local files.

**Prototype → playtest → revise.** Three evidence sources support the loop:

| Evidence | What it helps establish | What it cannot establish alone |
| --- | --- | --- |
| Automated mechanical diagnostics | Correctness, progress, action consequences, and strategy behavior under reproducible conditions | Whether humans enjoy playing |
| Human-play telemetry | Choices, failures, retries, progression, and voluntary replay | Why a player continued or stopped |
| Player reports | Reported enjoyment and explanations of the experience | A complete or infallible account of behavior |

Use controlled scenarios, reproducible seeds, and multiple strategies where appropriate. Treat apparent dominance, repetition, or bot performance as diagnostic signals, not automatic judgments about fun. AI-generated personas and critiques can suggest hypotheses but do not count as independent player evidence.

Keep **enjoyment**, **desire to continue**, and **actual voluntary replay** as separate measurements. A short post-play report might ask for enjoyment from 0 to 10, whether the player wants another run, and an optional explanation. Ask targeted questions about agency, competence, or absorption when testing a specific hypothesis rather than interrupting every session.

Associate telemetry and reports with the relevant experiment, version, variant, and session. Collect only necessary data with appropriate consent, and distinguish exits from crashes or missing telemetry. Investigate disagreements between reports and behavior rather than choosing whichever supports the preferred conclusion.

## Record each revision

Keep a versioned experiment record with:

1. **Observation:** What happened and the evidence behind it.
2. **Competing explanations:** Plausible causes, especially when signals are ambiguous.
3. **Hypothesis:** The explanation being tested and what could contradict it.
4. **Prediction:** What should improve and what might worsen.
5. **Intervention:** A bounded mechanic or tuning change.
6. **Comparison:** Baseline and candidate results, uncertainty, and conflicting signals.
7. **Decision:** Keep, revert, or investigate further, with reasons.

Choose measurements and decision criteria before reviewing candidate results. Preserve source versions, seeds, test conditions, documented failures and reversions; keep generated outputs local. Account for learning, prior experience, and exposure order; use randomized assignment when practical. Small samples justify provisional decisions, not broad causal claims.

Record the originating AI proposal and human contributions, especially human-supplied diagnoses or design choices. This makes AI-led design distinguishable from AI implementation of a human design. Document claimed novelty without assuming that an AI-generated mechanic is original.

## Evaluate the game and the method separately

**Game outcome:** Do the intended players report enjoyment and voluntarily replay? Does the candidate improve their experience relative to a baseline?

**Method outcome:** Which diagnostics helped? Did AI predictions survive playtesting? Could AI distinguish explanations and choose informative revisions? Where was human judgment necessary?

A disappointing game can still teach us something about the method. A successful game does not establish that the method works generally. Claims of faster development need evidence comparing iteration cost and results.

Do not optimize retention or one enjoyment score while ignoring audience differences, contradictory evidence, or player experience. Do not change success criteria after seeing results or present retrospective explanations as proven causes.

## Working in this repository

Read [AGENTS.md](AGENTS.md) for contributor and agent instructions. Work items and blockers live in **Beads**, not Markdown task lists; experiment records hold research evidence rather than a duplicate backlog.

```bash
bd prime       # Load the issue-tracking workflow
bd ready       # Find available work
bd show <id>   # Inspect a work item
```

Use each Godot experiment's own setup and playtest instructions. Borrowed Turns is the first playable prototype; its functional checks do not establish enjoyment or a successful game-design method.
