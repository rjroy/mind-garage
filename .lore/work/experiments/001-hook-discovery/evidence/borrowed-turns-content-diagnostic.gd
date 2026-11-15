extends SceneTree
const Encounter = preload("res://model/encounter.gd")
const Content = preload("res://content/escape.gd")
var failures := 0
func _initialize():
 print("fixture=", JSON.stringify(Content.DATA))
 for variant in ["V1", "V2", "V3", "V4", "V5", "V6"]:
  for capture in [false, true]:
   var g = Encounter.new()
   g.configure(Content.DATA, variant, false)
   var actions = [{"type":"move","to":[2,3]}, {"type":"move","to":[3,3]}]
   if capture:
    if variant == "V2":
     actions.append({"type":"move","to":[3,4]})
     actions.append({"type":"capture","source":"b","approach":[4,4]})
     actions.append_array([{"type":"move","to":[5,4]}, {"type":"move","to":[6,4]}, {"type":"move","to":[6,3]}])
    else:
     var cap = {"type":"capture","source":"b"}
     if variant == "V6": cap.target = [3,1]
     actions.append(cap)
     if variant == "V5":
      actions.append_array([{"type":"move","to":[4,3]}, {"type":"move","to":[5,3]}, {"type":"move","to":[6,3]}])
     else:
      actions.append_array([{"type":"move","to":[4,3]}, {"type":"move","to":[5,2]}, {"type":"move","to":[6,2]}, {"type":"move","to":[6,3]}])
   else:
    actions.append_array([{"type":"move","to":[4,3]}, {"type":"move","to":[5,2]}, {"type":"move","to":[6,2]}, {"type":"move","to":[6,3]}])
   print("CASE variant=", variant, " capture=", capture)
   for action in actions:
    var verdict = g.assess(action)
    var ok = g.act(action)
    print(JSON.stringify({"command":action,"legal":verdict.legal,"accepted":ok,"reason":verdict.reason,"state":g.snapshot()}))
    if not verdict.legal or not ok:
     failures += 1
     break
   print("RESULT ", variant, " capture=", capture, " status=", g.snapshot().status, " hp=", g.snapshot().player.hp)
   if g.snapshot().status != "won": failures += 1
 quit(1 if failures else 0)
