extends SceneTree
const E = preload("res://model/encounter.gd")
const F = preload("res://tests/fixtures.gd")
func _initialize():
 var board = F.board()
 board.enemies = [F.foe("source",[1,4],[1,0],F.ability("burst",3,1,3,true)), F.foe("tie",[2,2],[1,0],F.ability("bolt",1,1)), F.foe("xdom",[5,4],[1,0],F.ability("bolt",1,1)), F.foe("ydom",[4,5],[1,0],F.ability("bolt",1,1))]
 var game = E.new()
 game.configure(board,"R2",false)
 var capture = game.act({"type":"capture","source":"source"})
 var command = {"type":"release","target":[3,3]}
 var preview = game.assess(command)
 var committed = game.act(command)
 var destinations = {}
 for event in game.snapshot().events:
  if event.type == "displace": destinations[event.actor] = event.to
 print("capture=",capture," legal=",preview.legal," commit=",committed," preview_match=",preview.preview == game.snapshot())
 print("displacements=",JSON.stringify(destinations)," events=",JSON.stringify(game.snapshot().events))
 var ok = capture and preview.legal and committed and preview.preview == game.snapshot() and destinations.get("tie",[]) == [1,2] and destinations.get("xdom",[]) == [6,4] and destinations.get("ydom",[]) == [4,6]
 print("dominant axis and horizontal tie: ","PASS" if ok else "FAIL")
 quit(0 if ok else 1)
