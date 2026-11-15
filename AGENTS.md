# Agent Instructions

## Project: Mind Garage

This repository hosts multiple experiments in AI-led game design, not one predetermined game. The shared question is whether AI can originate a central mechanic and refine it into repeatable enjoyment through automated diagnostics, human play, and evidence-led iteration.

Mind Garage is the name of the experimental effort, not a game title. Give individual game prototypes their own names; Borrowed Turns is the current working title for the first selected direction.

Read [README.md](README.md) for the project overview and these shared foundations before proposing or changing an experiment:

- [Experiment brief](.lore/work/notes/ai-game-design-experiment.md): research question, validation layers, iteration protocol, and guardrails.
- [AI, novelty, and fun](.lore/work/notes/ai-design-novel-fun.md): what the retained accounts do and do not demonstrate.
- [What makes games fun](.lore/work/notes/what-makes-games-fun.md): selective research starting points, not universal design rules.

### Experiment scope and authorization

- Give each experiment a distinct identity, bounded question, and its own prototype, configuration, results, and run instructions. Keep changes and evidence attributable to that experiment; do not silently apply its assumptions to others.
- The initial intended audience is one player: Ronald. Explore his enjoyment and voluntary replay; do not generalize his results to a wider audience. Multiple sessions from one player are not independent player samples.
- Build playable experiments in Godot using the tools available here. Blender is available as an optional supporting tool, not a requirement for 3D or authorization to create assets. Verify installed versions and needed capabilities before committing to an implementation approach; do not assume plugins or external services are available.
- Start small enough to support repeated revisions. No particular genre, 2D/3D approach, target platform, or telemetry platform is prescribed. Share infrastructure when an actual need warrants it.
- The notes are exploratory context, not authorization to implement a game. Before implementation, settle the prototype and intended audience, development constraints, telemetry approach, recruitment, comparison design, stopping criteria, executable correctness checks, and practical decision thresholds with the user.
- Preserve the originating mechanic proposal, its claimed distinctive features, and human contributions. An AI proposal is not proof of originality. Human playtest feedback is compatible with AI-led design; record when humans instead supply a diagnosis, choose a change, or reject an interpretation.

### Evidence and iteration

- Read the [player brief](.lore/work/intents/player-brief.md) for Ronald's stated preferences and agreed player promise. Before choosing a hook or core mechanic, use [`discover-game-hook`](.agents/skills/discover-game-hook/SKILL.md). Keep reusable procedure separate from player preferences and per-game decisions.
- Store each experiment's research record at `.lore/work/experiments/<experiment-id>/record.md`, starting from the discovery skill's [template](.agents/skills/discover-game-hook/templates/experiment-record.md). Preserve input snapshots and procedure versions for fresh repetitions, and build/configuration/seed/save-state manifests for replay. Player learning cannot be reset; repeated AI generation need not yield identical proposals.
- For a new mechanic, use the project-local [`explore-mechanic`](.agents/skills/explore-mechanic/SKILL.md) skill: propose six alternative versions, build minimal individually playable variants, screen with recorded automated evidence, and compare human playtests. These are alternative rules for one mechanic, not six scenarios using unchanged rules.
- Use three complementary evidence layers: reproducible mechanical checks, consent-based human-play telemetry, and player reports. Select diagnostics for the actual mechanic rather than treating a generic checklist as a definition of fun.
- Automated checks can expose invalid states, deadlocks, weak choices, or apparent strategy dominance. Simulations and AI personas are not independent evidence of human enjoyment.
- Measure enjoyment, desire to continue, and actual voluntary replay separately. Retention, session length, difficulty, and strategy diversity are not substitutes for enjoyment. Treat agency, mastery, connection, and absorption as hypotheses to test with the intended players.
- For each revision, retain an experiment record: observation, competing explanations, hypothesis and possible disconfirmation, prediction and risks, bounded intervention, baseline/candidate comparison, and keep/revert/investigate decision.
- Choose measurements and decision criteria before inspecting candidate results. Preserve versioned builds, seeds, test conditions, and failed experiments. Account for learning, player experience, exposure order, uncertainty, and contradictory signals; randomize comparisons when practical.
- Keep telemetry definitions stable and associate events and reports with experiment, version, variant, and session. Distinguish genuine exits from crashes or missing events. Collect only necessary data with appropriate consent.
- Report game outcomes separately from method outcomes: whether intended players enjoy and replay the game versus whether AI diagnoses problems, makes useful predictions, and chooses productive revisions. Small samples support provisional decisions; one successful game does not establish a general capability or prove faster development.

Use Beads for actionable work and blockers. Experiment records document hypotheses and evidence, not a parallel task tracker. Preserve the source notes as context; do not rewrite them to fit later results.

## Issue Tracking

This project uses **bd** (beads) for issue tracking. Run `bd prime` for full workflow context.

> **Architecture in one line:** Issues live in a local Dolt database
> (`.beads/dolt/`); cross-machine sync uses `bd dolt push/pull` (a
> git-compatible protocol), stored under `refs/dolt/data` on your git
> remote — separate from `refs/heads/*` where your code lives.
> `.beads/issues.jsonl` is a passive export, not the wire protocol.
>
> See [SYNC_CONCEPTS.md](https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md)
> for the one-screen overview and anti-patterns (don't treat JSONL as the
> source of truth; don't `bd import` during normal operation; don't
> reach for third-party Dolt hosting before trying the default).

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work atomically
bd close <id>         # Complete work
bd dolt push          # Push beads data to remote
```

## Non-Interactive Shell Commands

**ALWAYS use non-interactive flags** with file operations to avoid hanging on confirmation prompts.

Shell commands like `cp`, `mv`, and `rm` may be aliased to include `-i` (interactive) mode on some systems, causing the agent to hang indefinitely waiting for y/n input.

**Use these forms instead:**
```bash
# Force overwrite without prompting
cp -f source dest           # NOT: cp source dest
mv -f source dest           # NOT: mv source dest
rm -f file                  # NOT: rm file

# For recursive operations
rm -rf directory            # NOT: rm -r directory
cp -rf source dest          # NOT: cp -r source dest
```

**Other commands that may prompt:**
- `scp` - use `-o BatchMode=yes` for non-interactive
- `ssh` - use `-o BatchMode=yes` to fail instead of prompting
- `apt-get` - use `-y` flag
- `brew` - use `HOMEBREW_NO_AUTO_UPDATE=1` env var

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:970c3bf2 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   bd dolt push
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->

<!-- BEGIN BEADS CODEX SETUP: generated by bd setup codex -->
## Beads Issue Tracker

Use Beads (`bd`) for durable task tracking in repositories that include it. Use the `beads` skill at `.agents/skills/beads/SKILL.md` (project install) or `~/.agents/skills/beads/SKILL.md` (global install) for Beads workflow guidance, then use the `bd` CLI for issue operations.

### Quick Reference

```bash
bd ready                # Find available work
bd show <id>            # View issue details
bd update <id> --claim  # Claim work
bd close <id>           # Complete work
bd prime                # Refresh Beads context
```

### Rules

- Use `bd` for all task tracking; do not create markdown TODO lists.
- Run `bd prime` when Beads context is missing or stale. Codex 0.129.0+ can load Beads context automatically through native hooks; use `/hooks` to inspect or toggle them.
- Keep persistent project memory in Beads via `bd remember`; do not create ad hoc memory files.

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.
<!-- END BEADS CODEX SETUP -->
