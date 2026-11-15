# Mind Garage

A workspace for multiple experiments in AI-led game design. Each experiment explores a small, replayable game and the process used to find its fun.

The shared research question is: **Can AI originate a central game mechanic and drive its refinement into something players enjoy and voluntarily return to?**

Human playtest feedback is part of that process. The question is not whether AI can build a game without human contact, or whether a clever prompt alone can establish that a design is novel and fun.

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

No common engine, genre, or telemetry service is prescribed. The notes do not authorize a particular implementation. Start with a prototype small enough to revise repeatedly and choose tools to fit the experiment.

## How we look for fun

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

Choose measurements and decision criteria before reviewing candidate results. Preserve builds, seeds, test conditions, failures, and reversions. Account for learning, prior experience, and exposure order; use randomized assignment when practical. Small samples justify provisional decisions, not broad causal claims.

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

Use each experiment's own setup and playtest instructions once defined. This README does not prescribe a runtime or assert that a playable prototype or validated result already exists.
