# Borrowed Turns — Theatrical Shadow Paper Prototype Brief

**Status:** Approved for an in-game visual experiment, **not** a final art-direction selection.  
**Origin:** Visual exploration conversation, November 15, 2026.  
**Project:** *Borrowed Turns* (working game title). *Mind Garage* is the broader AI-led game-design experiment.

## 1. Objective

Test whether **Theatrical Shadow Paper** makes the core mechanic of *Borrowed Turns* more readable, satisfying, and distinctive in the actual Godot prototype.

**Core visual proposition:** *The figures are the pieces. The shadows are the actions.*

Physical cut-paper figures remain relatively static. Their **unnatural, animated shadows** perform or preview intended actions. Capturing an enemy's ability removes that animated shadow from its owner; releasing the ability introduces that shadow somewhere else, where it performs the stolen action. Figures **do not cast ordinary physical shadows**. The absence is intentional, not a rendering defect.

This is an experiment in visual communication and feel. Do not add gameplay rules to justify the visual treatment.

## 2. Established gameplay context (not a request to change mechanics)

- Ordinary protagonist carrying a stolen artifact escapes pursuers in a small grid-based, turn-based encounter.
- Capturing an announced enemy ability is free, initially requires close proximity, and has no per-turn cap.
- Movement has a separate budget and can interleave with actions and capture.
- Releasing a captured ability costs an action and uses that ability's range.
- Holding an ability creates pressure to release it before a deadline.
- Replacing a held ability or allowing it to expire causes that ability's specific backlash, ideally discharging where the player stands; it may also affect nearby pursuers.
- No harmless discard.
- Exact timing, budgets, abilities, and setting are unsettled. Preserve the current prototype's mechanics unless a separate design decision changes them.

## 3. Visual identity

**Medium:** Deliberately theatrical cut-paper and shadow-puppet language, not toy-store papercraft, *Paper Mario*, or a generic particle-heavy fantasy game.

- Flat, legible cut-paper figures with distinct silhouettes; comparatively limited pose changes.
- Layered paper scenery, visible stage-like composition, graphic negative space, and a readable grid.
- Animated shadows are the primary expressive moving elements. Their motion may be unnatural and independent of physical lighting.
- The protagonist's **lamp** is a promising visual focal point and potential carrier of captured shadow. It is **not yet established** as the stolen artifact or as a gameplay light-radius mechanic.
- Sophistication comes from silhouette design, articulation, staging, timing, and visual metaphor—not simply making the palette dark or the lighting dramatic.
- Preserve a playful quality without making the figures childish or bobble-headed. Serious emotional stakes and handcrafted visual playfulness can coexist.
- Do not require physically accurate shadows; in fact, ordinary shadows are specifically excluded.

## 4. Prototype visual states

| State | Minimum visual behavior | Readability question |
| --- | --- | --- |
| Enemy intent | A recognizable animated action-shadow is associated with the announcing pursuer, showing what it intends to do. | Can the player identify the owner, threatened area, and action? |
| Capture | The animated shadow detaches from the pursuer and transfers to the player/lamp. The enemy's action-shadow disappears. | Is ownership transfer unmistakable and satisfying? |
| Held power | The captured shadow remains visually attached to the protagonist or lamp; a clear pressure/deadline indication persists. | Can the player identify the held action and urgency without visual clutter? |
| Release | The captured shadow appears at the selected valid location/direction and performs the stolen action. | Is the action visibly the *same* one that was stolen, now under player control? |
| Backlash | The held shadow performs its ability-specific uncontrolled discharge around the player's position when replaced or expired. | Is backlash distinct from deliberate release, and is its danger legible? |

**Key rule:** Do not replace the animated silhouette with a conventional purple energy projectile merely because that is easier to depict. Effects may support the shadow, but the shadow itself should remain the subject.

## 5. Recommended smallest in-game experiment

Build a **vertical slice of one existing ability**, not a full visual overhaul.

1. Choose an existing pursuer and announced action in the prototype; avoid inventing a new ability solely for this test.
2. Represent that action with a short looping **flat silhouette animation** attached visually to the enemy. Keep its threatened tiles legible using the existing telegraph or a minimal overlay.
3. On capture, visibly transfer the silhouette to the player/lamp and stop the enemy's action-shadow animation. Do **not** add an ordinary fallback shadow to the enemy.
4. While held, loop a recognizable version of that same silhouette near the player. Retain a distinct deadline indicator; do not rely solely on animation speed to convey time.
5. On release, move/reinstantiate the same action-shadow at the chosen target and play its action. On backlash, play its distinct local discharge at the player's position.
6. Test the sequence at **actual gameplay zoom**, including with multiple pursuers and overlapping threats. Also inspect still frames: information must not become unintelligible when animation pauses.

Use placeholder geometry, paper shapes, simple tweening, or shader effects as appropriate. This brief does not prescribe a 2D/3D implementation, animation technology, or production asset pipeline.

## 6. What to evaluate

Evaluate independently, rather than collapsing everything into one preference score:

1. **Image appeal:** Do I like looking at this?
2. **Game appeal:** Do I want to play a game that looks and moves like this?
3. **Tactical clarity:** Can I read enemy intent, capture, ownership, held power, release, and backlash at gameplay scale?
4. **Distinctiveness:** Does stealing a shadow feel different from copying a spell or attack?
5. **Production feasibility:** Can a small library of silhouette animations communicate different abilities without disproportionate authoring cost?

Specific failure signals: the animated shadows obscure the grid; enemies become unreadable without ordinary shadows; the transfer feels like a particle spell rather than removal of an action; held shadows overlap or conceal other threats; backlash looks identical to a controlled release; static figures make the scene feel lifeless rather than theatrical.

## 7. Boundaries and unresolved decisions

- **Do not select final art direction** based on this experiment. The original six candidates remain available.
- Do not create finished assets or expand into a full art pipeline yet.
- Do not introduce new lighting, shadow positioning, or lamp-range rules.
- Do not decide that the lamp and stolen artifact are the same object without a separate design discussion.
- Do not invent setting, enemies, abilities, or exact turn budgets to support visuals.
- Do not infer general audience appeal from Ronald's personal feedback.
- Do not assume the AI concept images are mechanically or spatially accurate; several failed to follow the intended action sequence.

**Open design questions:** How literally should a shadow resemble its enemy's announced action? How should multiple simultaneous animated intentions coexist? How can a shadow remain legible when held without covering the protagonist? How should different ability-specific backlashes read? What minimal motion is needed in the figures themselves?

## 8. Exploration provenance and decisions

### Ronald-originated observations and decisions

- Cut-paper imagery has nostalgic appeal, invites playfulness, and initially appeared tactically clear; worth exploring, **not selected**.
- Maturity should come from artistic construction and emotional tone, not merely darker lighting. Japanese shadow puppetry is a stronger conceptual reference than a children's cut-and-build craft book; avoid *Paper Mario* or bobble-head toy aesthetics.
- The initial three-way comparison looked too similar, largely varying lighting; genuinely different construction languages were needed.
- **Theatrical Shadow Paper** is the direction Ronald most wants to explore next.
- The figures should be relatively static while the shadows animate. Capturing removes the shadow from its animation; releasing adds it back elsewhere.
- The unnaturalness is desirable: **characters must not cast ordinary shadows**.
- There is enough visual direction to test in-game; further concept-image generation is not currently needed.

### Agent-originated proposals (hypotheses, not approved requirements)

- Use the lamp as a focal point for transferring and carrying the stolen shadow.
- Keep the stolen silhouette recognizable throughout capture, hold, release, and backlash.
- Use a short, controlled one-ability slice before investing in broad art production.
- Consider the production benefit of relatively static figures plus reusable shadow animations; verify rather than assume it.

### Concept-image limitations

- Earlier comparisons repeated similar fantasy imagery and varied lighting more than construction.
- The later five-panel action sequence did not faithfully realize the requested mechanics and drifted toward conventional magical effects.
- Treat those images as **mood references only**, not as specifications or final art.

## 9. Suggested next handoff

In the existing Godot prototype, identify the smallest existing encounter and ability that support an **announce → capture → hold → release / backlash** demonstration. Implement the minimum visual treatment, then review a short gameplay recording and stills at real gameplay scale against the evaluation questions above. Record Ronald's reaction separately from agent observations and keep the result reversible.

**Decision gate:** After testing, decide whether to iterate on Theatrical Shadow Paper, compare it with another candidate, or reject it. Do not automatically graduate this experiment into the game's production art direction.
