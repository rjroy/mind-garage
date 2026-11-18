---
title: "Experiment 006-session-game: A game for one sitting"
date: 2026-11-17
status: completed
tags: [game-design, experiment, discovery]
related: [.lore/work/intents/player-brief.md, .lore/work/research/game-hooks-and-player-promises.md]
---

# Experiment 006-session-game: A game for one sitting

## Inputs and provenance

- **Stage:** The initial discovery below offered three pitches. Ronald selected Last Light on the Rink by activating a goal for a standalone complete playable evening, from skating through a player-shaped finale, bow and restart. Borrowed Turns stays untouched.
- **Repository input snapshot:** `dbf1467f6c4c2f80ab968ab8ccb8d9bfea93d612`. The input files below are tracked and matched this commit when read. Recover one with `git show dbf1467f6c4c2f80ab968ab8ccb8d9bfea93d612:<path>`.
  - `AGENTS.md` and `README.md`, including the concluded Borrowed Turns experiment and Ronald's verdict that it kept answering what a player could solve rather than what he might enjoy.
  - `.lore/work/intents/player-brief.md` and `.lore/work/research/game-hooks-and-player-promises.md`.
  - `.lore/work/notes/ai-game-design-experiment.md`, `.lore/work/notes/ai-design-novel-fun.md`, and `.lore/work/notes/what-makes-games-fun.md`.
  - `.agents/skills/discover-game-hook/SKILL.md`, its `templates/experiment-record.md`, and `.agents/skills/explore-mechanic/SKILL.md`.
- **Human direction, relayed by the parent:** “User wants a genuinely new Godot game, NOT Borrowed Turns, full single-session experience rather than research as deliverable.” The delegated brief asks for three distinct playable pitches with embodied actions, a first minute, a midrun development and a payoff, plus a risk and cheap probe for each. It favors memorable tactile, amusing or expressive play and rules out repackaged grid or combat puzzles. The eventual deliverable is a game, not this discovery record or a collection of tests.
- **Existing player preference:** Ronald is the intended player. Choices that change play and a new way to play after completion are attractive hypotheses. The old roguelite examples are not design requirements. Each pitch gives the first session its own ending; a new option afterwards is a bonus, not a missing chapter.
- **Creative provenance:** Initial game concepts, mechanics, working titles, probes and recommendation by Creator, OpenAI GPT-6.2 Sol (`openai/gpt-6.2-sol`). No additional mechanic supplied by Ronald, and no selection or play feedback yet recorded here.
- **Tool check:** `command -v godot` returned `/usr/bin/godot`; `godot --version` returned `4.7.2.stable.arch_linux.ed1daf0bf`. No rendering, audio, input, physics or export capability was checked. No plugin, Blender or external service is assumed.
- **Assumptions, not requirements:** Roughly 10–15 minutes for one complete session, with one main space or a short continuous route. A simple 2D presentation is plausible for all three; input details below are proposals. Run length and any optional replay structure are not yet agreed.

## Discovery

### A. Last Light on the Rink

**Promise and action.** Leave a line, catch it at speed, then see a troupe skate it with you. Steer a skater on slippery ice. Hold the edge control to dig in and cut a groove; the sharp carve costs speed. Release to glide. If your blade meets a groove at a shallow angle, it seats in the cut and carries you along its curve with less sideways slip. Lean out to leave it. The line is not drawn in a menu, traced to meet a score, or replayed as fixed input. You skate it into the rink and your later motion responds to it.

- **First minute:** Take a push across the empty rink, skid past a lantern, carve a broad hook and come back into it. Hear the blade go from scraping to humming as it seats in your own line.
- **Midrun:** Two lantern skaters join rehearsal. They take grooves you cue them into. Cut an easy loop for both to follow, or lay separate arcs so one sweeps around the outside while the other slips through the middle. Your choice changes where you can meet them at speed, not what points you bank.
- **Payoff:** The house lights go down for the rink's closing show. Cue the troupe onto the paths you made, skate with them, then lead the last glide to centre ice and bow. A missed join gives you a scrappy show, not an unfinished session. The end unlocks a reverse-edge move so you can enter a groove against its original direction and stage counterflow in a future show.
- **Risk and cheapest probe:** Lines could feel like rails that wrest control away, or the evening could become route planning instead of skating. If separately approved, try one empty rink, one groove and the ability to peel out, without followers or goals. The signal is wanting to carve or re-enter a line for how it feels, before any reward exists. Fighting accidental catches, or returning to a groove only when told to, cuts against the pitch.

### B. Last Call for Thunder

**Promise and action.** Run a live farce from the wings without saying a word. Drag a mallet, bell or thunder sheet to the left or right wing. Tap, strike or shake it with the pointer. Where and how hard you play changes what the two performers do onstage. A tentative knock draws a curious guest; a sharp clang sends her under a table and draws the night clerk to investigate. The challenge is to improvise with the bodies in front of you, not hit prescribed notes or dub fixed footage.

- **First minute:** A guest stands stranded between two doors. Tap the desk bell on the right, watch her head turn and her feet follow. Try a harder hit and get a duck instead of a step.
- **Midrun:** The clerk keeps intercepting the guest. Rattle the thunder sheet on the far side to draw him away, then coax her out with the bell. If you accidentally spook her again, use the clerk's search as setup rather than restarting the scene.
- **Payoff:** In the third scene, get them to pass each other at the desk and discover they've swapped suitcases. Their success, near miss, or last-second mix-up determines the closing gag and curtain call. The ending opens an echo pedal that plays your last gesture back from the opposite wing after a short delay, leaving your hands free to perform the reply in a future show.
- **Risk and cheapest probe:** The cast could feel like a table of hidden button combinations; jokes could need too much animation and bespoke sound. If approved, try a 20-second scene with one prop, two performances of it and two visible actor reactions. Can the player read the response, intentionally change it and want to make a joke with the change? A repeatable reaction without playful intent is not enough. The target game should make the source, force and reaction legible visually as well as audibly.

### C. This House Is Leaving

**Promise and action.** Walk the last neighborhood diner to its new address by throwing its furniture around. Grab and drag the heavy booth or icebox inside a side-on cutaway. Moving weight ahead of the planted foot pitches the building into a stride; pulling back catches the step. The legs respond to loading rather than direct steering. Loose furniture keeps sliding briefly, so a good stride has a windup, a swing and a thump.

- **First minute:** Yank the booth toward the front. The diner leans and stamps out onto the street, rattling the cutlery. Pull it back to stop before a newspaper stand; overcorrect and the diner takes an embarrassed step backward.
- **Midrun:** At a steep curb, choose between shoving the icebox for a big step or feeding the booth forward and back for a pair of short ones. A deep lean makes the loose crockery rush across the counter. A spill or a knee-down stumble makes a mess but doesn't make you repeat the street.
- **Payoff:** Lower the shaking diner onto its new seaside foundations, level the floor and flip the sign to OPEN. The first customer orders breakfast in whatever state you got the place there. Completion opens a rolling upright piano: brace it into a corner for stable footing or release it downhill for a rolling weight transfer you couldn't make with the booth.
- **Risk and cheapest probe:** Furniture might just be a slower left/right key, or the step timing might feel arbitrary. If approved, try a room with one sliding weight, one curb and a recoverable stumble. Look for intentionally different short and long steps and for amusement at the recovery. If the best or funniest thing is always to pin the object at one end and wait, the interaction is not delivering the promise.

### Adjacent games and distinctive claims

Pages accessed 2026-11-17. These are descriptions of available interactions, not firsthand play, enjoyment evidence or an exhaustive novelty search.

| Direction | Source-backed overlap | Proposed difference |
| --- | --- | --- |
| Last Light on the Rink | [Line Rider](https://www.crazygames.com/game/line-rider), hosting page: draw a line and a rider rides it. [Figure Skating Legends](https://store.steampowered.com/app/3357130/Figure_Skating_Legends/), developer listing: choreograph and execute custom routines scored for skating elements and artistry. | Make the line by skating, then feel your own earlier cut guide your next pass. Reuse it as live choreography for others, not as a routine selected from a move list or a drawn line watched in playback. |
| Last Call for Thunder | [Foley Fever](https://barissurer.itch.io/foley-fever), developer page: perform prop sounds for a playing silent film via cues and improvisation, then watch the result. [Stagehand](https://redes01.itch.io/stagehand), developer page: change a set to redirect an actor whose moves are locked. [Dubbing Heroes](https://spotline.itch.io/dubbing-heroes-in-a-foley-of-violence), developer page: narrate and make noise for an interactive story using a microphone; the listing does not specify what the sounds change. | Force, timing and location of a physically performed sound change live performers' choices. There is neither locked footage nor a fixed move track to rearrange. |
| This House Is Leaving | [REKA](https://store.steampowered.com/app/1737870/REKA/), developer listing: build and furnish a walking cottage. [Baby Steps](https://store.steampowered.com/app/1281040/Baby_Steps/), developer listing: place each footstep yourself in physics-based walking. | Furniture is how you shift the diner's centre of mass and make it step, not decoration or a load you carry with ordinary controls. The foot is an effect of your input, not the thing you command. |

## Findings and next decision

**Recommend A, Last Light on the Rink.** Its satisfying moment, cutting a turn and catching it cleanly on the next pass, should be available before there is anything to solve. The ending asks the player to do that same thing with company and an audience, so it pays off what the player did rather than just playing a reward animation. It can all happen in one rink. *Last Call for Thunder* is the stronger comedy pitch but depends on readable actor behavior and authored reactions. *This House Is Leaving* is the stronger slapstick pitch but hinges on making weight shifts feel like moving a body rather than operating a finicky switch.

Ronald selected the rink and authorized building it through to a verified full session. The important uncertainty is whether cutting and catching a line feels good before there is any social or visual payoff. This is not answered by testing an input sequence.

## Build boundary and verification criteria

One short continuous evening, immediately playable, without a variant chooser or permanent progression. Opening, rehearsal, finale and bow run on the same ice. Use procedural drawing and reactive synthesis rather than downloads, external asset services, or a 3D pipeline. No accounts, analytics, recruitment, persistence or consent-dependent data collection. Ronald is the intended player; future repeat sessions do not represent additional players.

Before judging the candidate, check responsive steering and coast; intentional carve, catch and peel; real follower travel over player-authored paths; two different input performances yielding different finale trajectories; a complete session without mandatory scores; and restart clearing old grooves and actors. Verify the actual configured Godot scene, rendering and audio where supported. Stop when one coherent evening is playable, not when a bot judges it fun. Scope excludes the discovery pitch's optional next-session unlock.

## Playable session

Run `godot --path games/last-light-on-the-rink` from the repository root. The evening opens immediately, reaches rehearsal at 28 seconds and the closing show at 112 seconds, then calls the cast to centre at 164 seconds. The shared bow waits for the last skater to arrive. There is no save file, seed dependency, required score, prototype selector, or unlock gate. Controls and the restart key are in the [game README](../../../../games/last-light-on-the-rink/README.md).

Godot 4.7.2 imported and launched a fresh source-only copy. The six focused runners (`model`, `cue`, `groove`, `parallel`, `bow`, `cue_feedback`) exited 0; run any with `godot --headless --path games/last-light-on-the-rink --script res://tests/<name>_run.gd`. The configured scene completed two different performances with normal keyboard event routing: `godot --headless --fixed-fps 60 --path games/last-light-on-the-rink --script res://tests/session_run.gd` reported `59/59 checks passed`. Both partners traversed their assigned cuts, finale trajectories differed between performances, and restart cleared the prior choreography. An empty evening also concludes.

Focused correction checks covered an unintentional catch beside a sampled or intersecting groove, the flash identifying the partner actually cued, and the player steering into the final seconds before returning for the group bow. Original audio was captured from the live PulseAudio path, including movement, cue, finale, pause/mute, bow and restart; the current synth produced no generator skips in that probe. Captured samples demonstrate signal, not subjective audio quality. No human play or voluntary replay is claimed.

A separate graphical playthrough using keyboard events and an isolated Wayland display rendered five 1152×720 frames: opening, rehearsal, finale, bow and good night. Two cues assigned two different player-drawn grooves; the final frame at `bow_time=4.53` showed all three skaters gathered and the “R Skate again” prompt. The render validator exited 0. To see the same phases without scratch tools, launch normally, carve and release two moving strokes in rehearsal, pressing E after each, and let the final bow finish.
