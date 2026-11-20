# Borrowed Turns — Visual Exploration Retrospective

**Scope:** From the initial six-direction exploration through selection of Theatrical Shadow Paper for an in-game experiment.

**Outcome:** A promising visual direction, a prototype brief, and a concept-art reference. The direction is ready for testing, but not established as the final art style.

## Executive summary

The exploration succeeded when it moved from describing aesthetics to investigating how a visual medium could express the game's central mechanic.

> **The figures are the pieces. The shadows are the actions.**

This emerged through collaboration. The agent proposed theatrical shadow puppetry and a lamp as a visual device. Ronald identified the stronger concept: physical figures remain relatively static while their animated shadows represent actions. Capturing an ability removes its shadow animation; releasing it restores that animation elsewhere.

The primary failure was insufficient differentiation between early visual alternatives. Several generated comparisons varied lighting, palette, and atmosphere while retaining nearly identical character designs and compositions.

The process improved when Ronald challenged those results and the agent generated separate, more structurally distinct treatments.

The final result was not a finished art style. It was a **testable visual hypothesis with a direct relationship to gameplay**.

## What worked

### 1. Broad exploration before commitment

Starting with six directions prevented the first attractive image from becoming the default art direction.

| Direction | Status at end |
|---|---|
| Illustrated Pursuit | Preserved, not evaluated |
| Miniature Chase | Preserved, not evaluated |
| Stolen Signal | Preserved, not evaluated |
| Cinematic Getaway | Preserved, not evaluated |
| Cut-Paper Caper | Positive feedback; explored further |
| Tactical Graphic Novel | Preserved, not evaluated |

This maintained alternatives while allowing deeper investigation of the direction that attracted Ronald.

### 2. Separating appeal from readability

The initial evaluation asked three independent questions:

- Do I like this image?
- Do I want to play a game that looks like this?
- Can I understand the threats and stolen power?

Ronald answered yes, yes, and clear for Cut-Paper Caper.

That provided a useful reason to continue exploring it without implying that other directions had failed.

### 3. Feedback challenged the underlying assumptions

Ronald identified that maturity and playfulness were being treated too much as palette choices.

His comparison between Japanese shadow puppetry and children's cut-and-build papercraft reframed the problem around construction, articulation, silhouette, and theatrical expression.

This was a substantive improvement to the exploration model, not merely an aesthetic preference.

### 4. The visual medium became part of the mechanic

The exploration became substantially more productive once shadow puppetry was connected to stealing announced actions.

The lamp, static figures, and animated shadows formed a coherent visual grammar for capture, holding, release, and backlash.

This was the strongest outcome because it suggested an identity that could only be fully evaluated through play.

### 5. The process stopped at the right point

Once the core visual hypothesis was clear, Ronald chose to move into the game rather than continue generating concept art.

This prevented concept exploration from becoming an endless polishing exercise.

## What didn't work

### 1. Early images were insufficiently distinct

The first three-way comparison of paper construction styles retained nearly identical scenes, character proportions, lighting, and effects.

Although the labels described different techniques, the generated results did not adequately demonstrate them.

**Root cause:** The comparison controlled too many visual variables while failing to force meaningful differences in the medium's construction language.

**Improvement:** Generate independent images with explicit structural differences, then compare them at a consistent gameplay scale.

### 2. Sophistication was confused with darkness

Early proposals implicitly associated bright colors with playfulness and dark lighting with maturity.

Ronald correctly challenged that assumption. A brightly colored shadow-puppet performance can be sophisticated; a dark scene populated by bobble-headed characters can still feel childish.

**Improvement:** Evaluate silhouette, proportions, material treatment, articulation, composition, and narrative tone separately from palette.

### 3. Image generation struggled with precise visual mechanics

The action-shadow sequence did not consistently demonstrate the requested behavior.

In particular, the images struggled to show the same shadow detaching, disappearing from its original owner, being held, and reappearing elsewhere. Some results drifted toward conventional fantasy magic effects.

**Improvement:** Use generated concept art for visual identity and mood, but use controlled animations or an in-engine prototype to validate precise spatial and temporal behavior.

### 4. The agent sometimes overexplained

Several responses developed elaborate visual systems before confirming whether the preceding visual experiment had succeeded.

This risked turning provisional interpretations into apparent design decisions.

**Improvement:** After each visual comparison, identify one observation, one uncertainty, and one proposed next test. Expand only when the feedback warrants it.

### 5. The process lacked a formal experiment ledger

Although decisions and attribution were discussed, there was no consistently maintained record separating predictions, observations, and conclusions across all iterations.

**Improvement:** Maintain a compact experiment record containing the hypothesis, generated reference, user feedback, failure modes, and next action.

## Key turning points

| Moment | Contribution | Effect |
|---|---|---|
| Six initial directions | Agent | Established a broad search space |
| Positive Cut-Paper feedback | Ronald | Identified a promising candidate |
| Questioning childlike presentation | Ronald | Introduced maturity as an exploration dimension |
| Shadow-puppetry analogy | Ronald | Shifted focus from palette to construction language |
| First three-way comparison failed | Ronald | Exposed insufficient visual differentiation |
| Three independent treatments | Agent | Produced more meaningful alternatives |
| Preference for Theatrical Shadow Paper | Ronald | Established a focused exploration branch |
| Lamp and shadow interactions | Agent | Connected visual identity with gameplay |
| Static figures, animated shadows | Ronald | Defined the central visual concept |
| No ordinary shadows | Ronald | Established deliberate unnaturalness |
| Decision to prototype | Ronald | Ended concept exploration at an actionable point |

## What we learned about the collaboration

The most productive pattern was:

1. **Agent proposes alternatives.** Provide meaningful choices, not just variations.
2. **Ronald reacts and challenges assumptions.** Identify what actually attracts or disappoints.
3. **Agent reframes and experiments.** Change the underlying hypothesis, not just polish.
4. **A testable concept emerges.** Move to implementation when play can answer more.

The agent was particularly useful for generating alternatives and proposing connections. Ronald's contributions were particularly important in rejecting weak distinctions, identifying the underlying aesthetic principles, and recognizing the mechanic that made the direction interesting.

This is a qualitative observation from one exploration, not evidence that the same division of responsibilities will always be optimal.

## Recommended changes for future Mind Garage experiments

1. **Require structural differentiation.** Before generating alternatives, state what must differ beyond color, lighting, and decoration. Reject comparisons that fail this requirement.
2. **Use one image per distinct direction.** Avoid multi-panel generation when the model keeps homogenizing the results. Assemble comparisons afterward if necessary.
3. **Separate aesthetic and mechanical hypotheses.** A beautiful image doesn't prove an animation will be understandable or satisfying during play.
4. **Keep feedback attribution explicit.** Record what Ronald proposed, what the agent inferred, and what remains untested.
5. **Use an experiment ledger.** For every meaningful iteration, retain the hypothesis, reference, observation, decision, and unresolved question.
6. **Define an exit criterion.** Stop generating concept art when the remaining uncertainty is better answered by a playable prototype.
7. **Do not treat generated images as specifications.** Document where the generator failed to follow instructions so those failures aren't accidentally implemented.

## Next experiment: In-game validation

The next stage should test whether the concept works when animated and interactive.

The minimum useful test is one enemy, one announced ability, one protagonist, and one capture/release cycle. The central questions are whether the shadow's motion communicates intent, whether removing it from the enemy communicates capture, and whether its reappearance communicates ownership transfer.

Backlash should then be tested as a separate consequence.

Success would mean the mechanic is readable and satisfying without relying on explanatory text or elaborate spell effects. Failure would not necessarily invalidate Theatrical Shadow Paper; it might indicate that the shadow animation, positioning, or visual feedback needs refinement.

## Final assessment

| Dimension | Assessment |
|---|---|
| Breadth of initial exploration | Good |
| Distinctiveness of first comparisons | Poor |
| Responsiveness to feedback | Good |
| User/agent co-creation | Strong |
| Precision of generated images | Inconsistent |
| Gameplay integration of visual ideas | Promising, untested |
| Final deliverable usefulness | Ready for prototype evaluation |

**The principal success was not finding an attractive art style. It was discovering a visual metaphor that expresses the game's defining mechanic.**

**The principal process lesson is that visual exploration should challenge its own assumptions.** When alternatives look too similar, generating more of the same is less useful than reconsidering what makes them different.

The most important unresolved question is whether this visual metaphor remains compelling at actual gameplay scale, with multiple simultaneous intentions and real player decisions.

That is now a question for the prototype rather than concept art.
