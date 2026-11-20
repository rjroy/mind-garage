extends SceneTree
const Encounter = preload("res://model/encounter.gd")
const Content = preload("res://content/escape.gd")
func _initialize() -> void:
 print("fixture=", JSON.stringify(Content.DATA))
 var failed := false
 for replacement in [false, true]:
  var g = Encounter.new()
  g.configure(Content.DATA, "R2", false)
  var commands := []
  if replacement:
   commands.append_array([{"type":"capture","source":"c"}, {"type":"capture","source":"a"}, {"type":"release","target":[3,3]}])
  for cell in [[1,3],[1,2],[1,1],[2,1],[3,1],[3,0],[4,0],[5,0],[5,1],[5,2],[5,3],[6,3]]:
   commands.append({"type":"move","to":cell})
   if cell != [6,3]: commands.append({"type":"end_turn"})
  print("CASE replacement=", replacement)
  for cmd in commands:
   var before: Dictionary = g.snapshot()
   var assessment: Dictionary = g.assess(cmd)
   var pure: bool = g.snapshot() == before
   var accepted: bool = g.act(cmd)
   var after: Dictionary = g.snapshot()
   print(JSON.stringify({"command":cmd,"assessment_legal":assessment.legal,"reason":assessment.reason,"accepted":accepted,"pure":pure,"preview_matches":assessment.preview == after,"turn":after.turn,"status":after.status,"player":after.player,"events":after.events}))
   if not assessment.legal or not pure or not accepted or assessment.preview != after:
    failed = true
    break
  var result: Dictionary = g.snapshot()
  print("RESULT replacement=", replacement, " status=", result.status, " hp=", result.player.hp, " turn=", result.turn)
  if result.status != "won": failed = true
 quit(1 if failed else 0)
