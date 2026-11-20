# Borrowed Turns

One small turn-based fight built around enduring an enemy attack to acquire its ability, then using it through Shine. Ronald reports the 5×5 version at `744fca3` felt good, engaging and puzzle-like, but not particularly replayable as the same encounter. Normal launch uses the accepted 7×7 Stage extent from `8275a48`, not a newly validated fight. It is not a run, unlock system or general enjoyment finding. Mind Garage names the research effort, not this game.

See the [game design and experiment index](../../.lore/work/games/borrowed-turns/README.md) for its research record.

## Run

Requires the installed Godot 4.7.2 executable. No packages, external services, downloaded fonts, telemetry or persistent saves. The Stage and source actors ship with the game.

From the repository root:

```bash
# Import source textures once after a fresh checkout, or open the Godot editor.
godot --headless --editor --path games/borrowed-turns --import
godot --path games/borrowed-turns
godot --path games/borrowed-turns -- --encounter=flanker
```

Normal play opens **Switcher** in **Stage** view: one damaging-swap opponent on the accepted 7×7 floor, with a 3-AP budget. **Switcher + B**, **Two pursuers** and the six solo trials are available from the start. All use the shared model and current Capture/Shine rules.

```bash
godot --path games/borrowed-turns -- --encounter=switcher
godot --path games/borrowed-turns -- --encounter=switcher-b
godot --path games/borrowed-turns -- --encounter=two-pursuers
```

The former Invert preview is not part of the current core rules; the retired `--invert` option is rejected. There is no progression gate.

**Stage** is the sole presentation. The retired `--presentation` option and unknown encounter values are rejected.

Requested window: 1280 × 800; minimum 1024 × 720. Native Controls follow actual viewport dimensions without globally shrinking fonts. A tiling compositor may refuse requested native dimensions. Phone/portrait/gamepad support is out of scope.

## Turn and controls

Defeat all foes. The goal and number remaining stay visible. There is no progression or unlock condition.

- **AP** means action points. Each turn starts with 3 AP. A confirmed cardinal step, arming Capture, or Shine costs 1 AP. Movement is one adjacent cell per command, not an automatic path.
- **Capture** arms without selecting a source. The next enemy attack that actually hits you deals its full normal damage and effects, then supplies your held ability if you survive. It does not cancel that attack or protect its other victims. Misses do not consume arming, which persists between turns. Arming twice is rejected.
- **Shine** uses the held ability without consuming it. You can activate it repeatedly while you have AP and its source remains alive.
- **End turn** is free. It resolves enemy attacks in source order, then living opponents' movement, then fresh aim and announcements. Aim stays fixed during your turn, though displacing a source translates its footprint. Each opponent retains its own one-step movement budget. Zero AP never auto-ends the turn.

Choose **Move**, **Capture**, **Shine** or **End turn**, then choose a target for Move/Shine. Inspect the predicted board overlay and summary; **Preview** lists exact ordered effects in the upper-stage Details sheet. A separate **Confirm** commits. **Cancel** or right click backs out of a prepared command without changing the model; it does not refund previously confirmed arming. End turn also previews and requires confirmation. **Recent events** contains committed events only.

Keyboard: Tab / Shift+Tab traverses controls; Space / Enter activates. M selects Move, C Capture, S Shine, E prepares End turn. With board focus, arrows inspect and Enter selects a cell; a separate Enter confirms. Esc cancels, Ctrl+R requests restart. Controls help does not advance play.

## Switcher: fixed-cell exchange

The Switcher chases using the existing one-step movement policy. When the player is cardinally aligned within range 2 with no intervening wall, it announces that exact cell. The target cell stays fixed during the player turn; moving away makes an empty-cell attack miss. Another living actor moved into the locked cell can become the victim instead. Its source position and wall/range validity still matter.

On a hit, both actors exchange positions first, then the victim takes 1 damage. Armed Capture acquires Swap only after these normal consequences, if the player survives. Borrowed Swap lets Shine target an occupied enemy cell on a clear cardinal line within range 2; it rejects empty, diagonal, self and blocked targets. Shine remains reusable until its source dies, including when a source-killing exchange completes its relocation.

The filled wash marks only the locked target cell. Hollow exchange pads and the connecting pulse explain the two positions; they do not mark damage along the corridor or an additional threatened source tile. The Switcher provisionally reuses A's accepted artwork but is named **Switcher** in the roster, Plans and Director. No new art or progression is involved.

Try solo first, then **Switcher + B**. The pair keeps B's three-wide shove unchanged, allowing exchanges to change who occupies its already announced region. Build, checks and interpretation limits are in [experiment 004](../../.lore/work/games/borrowed-turns/experiments/004-switcher/record.md).

## Holding and source-linked abilities

The single held ability retains its source identity, range, width, damage, radius and push capability. B's width three covers its centre lane and one lane on each side, forward of the origin, with walls and board edges clipping the actual footprint. Shine retains that width. Width does not extend forward range: narrow and wide activations stop at the selected target's distance.

Holding has no expiry or backlash. Arming while holding leaves the old ability available until a successful acquisition replaces it. Replacement causes no discharge. Shine itself cannot trigger armed Capture.

Defeating the source removes its held ability, regardless of who deals the killing blow. A Shine already resolving completes all its effects before the source link clears; an area attack is not truncated midway. This can make keeping a useful source alive valuable, but all opponents must ultimately be defeated. Lethal incoming damage still kills you rather than granting a rescue capture.

### Reading the board

- In Two pursuers, standees and **P / A / B** foot markers identify the actors. Coordinates are `[x,y]`, right/down.
- In Two pursuers, full-tile washes and moving wavefronts show current enemy intentions; cool A/diamond and warm B/circle identify their sources. Inspect/select an enemy or intention row for its exact footprint.
- Teal outlines/dots: legal candidates. Solid routes, outlined effect cells and hollow pawn positions: the selected command's exact prediction. Cross marks show predicted deaths. The live board changes only after confirmation.
- Cell inspection names overlapping enemy sources. Details shows ability range/shape/strength and complete current intentions, with scrolling where needed. Complete Preview/history lines also scroll; they are not hidden in tooltips.

Restart restores this fixture, including fresh budgets, empty storage and history. Win/failure leaves the final board/history visible and offers **Replay encounter**, with no confirmation needed for a finished fight.

## Event-driven shadow performance

An armed state is not a captured gesture. An enemy's strike and the player's recorded damage/displacement must play before the acquisition transfer. The held motif supports repeated Shine and clears when its source dies. Enemies continue announcing and attacking while their ability is held.

Full model-authored footprint markings remain authoritative. Rehearsal and preview cause no damage; a held motif does not imply its living source has been disarmed.

Finite shadow cues complete independently of persistent idle/held loops. Gameplay input waits for finite feedback, not an arbitrary scene sleep or endless animation. Restart cancels old visual work. The model commits once on confirmation; animation never decides gameplay results.

The earlier visual pilot does not establish enjoyment. [Experiment 003](../../.lore/work/games/borrowed-turns/experiments/003-active-opponents/record.md) records the accepted bargain, positive single-fight feedback and larger Stage. [Experiment 004](../../.lore/work/games/borrowed-turns/experiments/004-switcher/record.md) records the new Switcher solo/paired playtest.

## Theatre stage

The approved backdrop, paper floor and transparent foreground are composed in Godot 2D without changing their source pixels. The theatre receives the main viewport width rather than the old board column. Status and action strips remain visible; **Details** explicitly opens the upper-screen sheet, choosing Preview when a command is prepared, otherwise Plans. Selecting a command no longer automatically covers the performers. Long ordered previews, plans and history scroll within the sheet, not over the playable floor.

The grid follows the model's runtime width and height, not an image's painted cell count. The accepted extent is 7×7, player `[0,3]` and opponents `[6,0]`/`[6,6]`, using a wider/taller floor fit with no edge coordinate labels. Standee scale, Director and roster remain unchanged. At minimum 1024×720 the grid spans about 674×262 pixels; at 1280×800 about 779×303. Sampled cell centres remain clear of the original foreground artwork; Ronald accepts this presentation as “works great.” Other encounter footprints remain future design choices.

Stable crops, quarter-turns, subtle color variation and seams make cells read as separate paper pieces. The floor shader, board marks, actor feet and mouse targeting share one perspective map. This slice does not add a player-facing grid-size setting. On the dark floor, threats use light coral and legal choices use pale mint; their meaning is unchanged.

The Stage uses the approved standees and packaged backdrop puppets. Ronald accepted the visual baseline as sufficient for gameplay; the moving fights still need live play feedback.

### Active two-pursuer fight

```bash
godot --path games/borrowed-turns -- \
  --encounter=two-pursuers
```

The selector includes the three earlier fights and the six solo trials listed below. Changing encounters asks for confirmation; Cancel keeps the existing fight. Restart restores the selected encounter. Omitting the encounter option opens solo Switcher in Stage.

The five puppet textures ship in `res://assets/puppets/two-pursuers`; import them as described above after a fresh checkout. Their source and portable extraction recipes are documented in [`assets-source/borrowed-turns/two-pursuers`](../../assets-source/borrowed-turns/two-pursuers/README.md). An optional `--puppet-pack=<directory>` override accepts native RGBA `a-body.png`, `a-hands.png`, `b-body.png`, `b-hands.png` (290×145) and `p-lantern.png` (145×145). Missing or invalid material fails at launch; no substitute art is used.

The wall-free fight starts the player at the edge midpoint opposite the two corner opponents. A keeps the narrow shove; B's shove is three tiles wide. Health, damage, range and enemy movement are unchanged; acquisition no longer has a capture-reach requirement. Whether the revised bargain creates better choices or peril needs human play. The Stage ground plane yaws about 30 degrees; accepted standee sizes, source images and native foot anchors are unchanged. Small **P / A / B** source markers stay at the true actor feet, above overlapping art. Names and current HP appear in an always-visible roster to the right of the grid, below the Director. Click a roster row, visible figure pixels or a foot marker to inspect the same actor; transparent image padding clicks through. Roster slots stay fixed as figures move, and dead sources lose their row. Hover/focus a rear source to reduce front-piece opacity. With board focus, **[ / ]** cycles figures and Enter selects; arrows still inspect floor cells. **Alt-click** explicitly selects floor through figures. A legal floor target also takes priority when the overlapping actor is not a legal target for the chosen operation.

The upper theatre is not a map projection: A stays left, B right, player central. Only currently player-threatening announcements press forward; others stay watchful. Actual acquisition follows the enemy strike and creates a held motif beside/above the lantern handle. Both living enemies remain dangerous. Source ID plus acquisition turn distinguishes held ownership from a fresh announcement. No damage occurs during rehearsal or preview.

Confirmed Shine and enemy actions follow the shared controller's ordered event slices. Player reaction requires recorded player damage/displacement, including zero-damage pushes; enemy-only actions never invent a player hit. Map motion replays recorded movement/displacement and settles at the exact committed state. Acquisition and source-loss feedback must occur at their actual event boundaries rather than jumping to the final held state before the strike.

Voluntary enemy moves have finite slide stages after the old attacks. Ability displacement stays inside its owning attack. Input stays locked until this sequence finishes, then fresh next-turn warnings and Director rehearsal appear together. Arming and holding do not remove either source's warning. Restart cancels old-generation presentation without replaying combat. Watching waves never advances the model.

**Composition tradeoff:** taller standees overlap more depth rows. The playable grid begins lower, with an extended ungridded floor apron retaining the stage seam; this separates faces from the performance without moving logical actors apart. Face/lantern identity, rear-source access and source tabs need actual human play review at 1024×720 and normal size. Temporary puppets remain lower-resolution concept cutouts, not a finished matching cast or a general crowd director.

### Angled board and wavefront overlays

Ronald accepted the Director images and standee sizes, then selected source-driven moving curves for shove warnings. The retained **Two pursuers** encounter opens that presentation without a hidden appearance choice; Switcher uses its distinct single-cell exchange marks on the same floor. Earlier ribbon/stamp controls and runtime hand decorations are retired; checkpoint `38d7e3e` preserves that experiment for historical comparison. Source artwork and projection are unchanged.

Shove warnings cover every affected tile edge to edge, beneath the standees. Curved fronts travel from the attacker along the actual attack direction; they do not track the player. Swap instead marks its single locked cell and exchange endpoints. **Cool A/diamond** and **warm B/circle**, matching the foot markers and roster, identify the sources. Exact regions come from model-authored cells, not a convex hull, an extra source square or an invented destination. Floor material, grid, regions, motion, feet, depth sorting and picking share one ground-plane homography.

Capture does not remove an enemy's announced region. Mint marks show legal choices and exact command predictions, not additional enemy wavefronts. Costs, armed/held state, consequence summary, Confirm/Cancel and explicit Details remain available.

The ungridded apron retains the accepted horizontal theatre seam while sampling the yawed plane. Angle reduces alignment, not every possible overlap; rear-source access still matters. The concept's different character designs were not adopted. This iteration preserves the accepted visual baseline; moving opponents and tactical clarity still need human play feedback.

The roster replaces the previous large HP/source plates without shrinking the board or actors. It uses the same confirmed actor data for drawing and selection; preview damage does not update its HP before confirmation. The earlier static arrowhead and visibility-placement experiments failed the visual objective and are retired. The moving curves use the existing rehearsal clock: their cycle is 2.7 seconds while the Director retains its 1.8-second loop. Watching them never spends points, damages actors or advances a turn.

The focused scene runners reuse real controls with controlled fixtures:

```bash
godot --headless --path games/borrowed-turns --script res://tests/board_warning_run.gd
godot --headless --path games/borrowed-turns --script res://ui/board_comparison_smoke.gd
godot --headless --path games/borrowed-turns --script res://ui/smoke.gd -- --focus=armed-capture-shine
```

The shipped puppet pack is used by default. The current revision uses headless verification and a live human fight, not new screenshots or recordings. Older optional capture paths predate the active starting positions and are not this revision's verification gate. These injected-control checks are not physical input, human legibility judgments or independent proof of enjoyment.

For the human checkpoint, use normal launch and play one complete fight. Arm Capture, anticipate an incoming attack, survive it, then use Shine. Consider whether changing abilities is worth taking another hit and whether keeping a useful source alive creates a real choice. Mechanical feasibility alone does not establish enjoyment.

Focused checks (the real-scene checks use the shipped pack):

```bash
godot --headless --path games/borrowed-turns --script res://tests/standee_board_run.gd
godot --headless --path games/borrowed-turns --script res://tests/two_pursuer_presentation_run.gd
godot --headless --path games/borrowed-turns --script res://tests/puppet_assets_run.gd
godot --headless --path games/borrowed-turns --script res://ui/smoke.gd -- \
  --focus=two-pursuers-cli --encounter=two-pursuers
```

The standalone capture-motion study tool was retired after checkpoint `42702e3`; that checkpoint preserves its original launch and test instructions. The live two-pursuer rig retains the study glow shader.

Focused Stage checks:

```bash
godot --headless --path games/borrowed-turns --script res://tests/stage_projection_run.gd
godot --headless --path games/borrowed-turns --script res://ui/smoke.gd -- --focus=stage
```

Current verification is headless plus Ronald's live play. Older screenshot/recording procedures are historical and are not this revision's gate.

## Composing opponents

For a movement comparison, try `circler` and `lantern-guard`: both use a wide shove, but one circles while the other patrols a route relative to its starting cell. Other trial IDs are `flanker`, `deadeye`, `anchor` and `puller`. Launch any one directly, for example:

```bash
godot --path games/borrowed-turns -- --encounter=circler
```

`content/encounters.gd` lists selectable fights; `content/opponents.gd` supplies reusable opponent parts. A fixture's `opponent_definitions` dictionary maps stable definition IDs to dictionaries with:

- `name` and `stats.max_hp`.
- Optional `movement` with a `pattern` and `budget`.
- An `abilities` array of existing ability payload dictionaries.
- `decision`: `fixed` selects the first ability; `first_in_range` selects the first whose nominal footprint reaches the player at announcement, falling back to the first.
- `presentation`: an existing `A` or `B` kit.

The fixture's `enemies` entries each specify a distinct per-instance `id`, a definition ID, `pos` and `dir`. Multiple instances can share a definition and art, but their instance IDs remain distinct: source-linked abilities belong to the individual source, not every opponent using that definition.

Composing existing parts does not require edits to combat behavior. New effects, movement patterns or decision policies still require implementation. Bodies remain single-cell blockers; there is no traits, reactions or custom-body framework. The Stage retains its two opponent slots and shared A/B artwork. Slot, artwork and captured source are separate: two opponents can share a look without sharing health or ownership of Shine.

## Implementation and focused checks

From the repository root, run the model, the six catalog replays and the selector/Stage checks with:

```sh
for script in tests/run tests/stocked_opponents_run tests/stocked_routes_run \
  tests/stocked_scene_run tests/mixed_stage_roles_run tests/two_pursuer_presentation_run \
  ui/board_comparison_smoke ui/smoke; do
  godot --headless --path games/borrowed-turns --script "res://$script.gd" || exit 1
done
```

The [opponent trial record](../../.lore/work/games/borrowed-turns/experiments/005-opponent-library/record.md) includes the frozen control comparison and the limits of this evidence.

- `model/encounter.gd`: authoritative legality, AP, armed/held state, exact intentions, nonmutating assessments and ordered resolution.
- `ui/encounter_ui.gd`: native shell, selection/confirmation, input and presentation lifecycle. Enumerates candidate commands and assesses them; does not simulate geometry or damage.
- `ui/board.gd`: grid rendering, screen/cell conversion and presentation of model footprints/events. Actor movement/death markers follow model events; no displacement convention is reimplemented.
- `ui/presentation.gd`: theme, ability/event formatting and command summaries.
- `ui/shadow_presentation.gd`: detached deterministic `RefCounted` projection with `reset(snapshot, generation)`, `observe(before, command, after, generation)`, `advance(delta)` and `frame()`. Persistent announcements/held ownership are separate from finite attack/acquisition/Shine feedback. Inputs/outputs are deep copies; stale generations and unchanged transitions are ignored.
- `ui/smoke.gd`, `ui/smoke_fixtures.gd`: focused integration checks through actual scene controls with controlled inputs. They contain no alternate gameplay path or test-only production command.
- `scenes/encounter.tscn`: main scene.

```bash
godot --headless --path games/borrowed-turns --quit-after 3
godot --headless --path games/borrowed-turns --script res://ui/smoke.gd
godot --headless --path games/borrowed-turns --script res://tests/shadow_presentation_run.gd
```

The armed-Capture/Shine checks cover paid targetless arming, ordinary damage before acquisition, reusable held abilities, source-linked loss, exact wide geometry/endpoints, reset and terminal controls. Controller checks protect event ordering, later independent attacks, generations, detachment and slides. Real-scene checks activate actual button signals and emit viewport input; they are **not physical OS input evidence**, human visual acceptance or enjoyment. See the experiment record for which runners have actually passed at each checkpoint.

Runtime diagnostics print starts, submitted commands and results to stdout. Event history exists only in memory. Independent testing and review establish bounded technical evidence. Earlier rules and presentation experiments remain historical in `.lore/work/games/borrowed-turns/experiments/`; they are not parallel supported modes or current requirements. Regenerable evidence stays under ignored `.lore/local/`, never a runtime dependency or committed test artifact.
