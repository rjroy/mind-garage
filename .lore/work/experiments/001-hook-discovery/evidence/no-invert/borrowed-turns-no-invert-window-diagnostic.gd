extends "res://ui/smoke.gd"

class WindowObserver extends Node:
 func _notification(what: int) -> void:
  if what == NOTIFICATION_WM_CLOSE_REQUEST:
   print("WINDOW_DIAGNOSTIC notification=WM_CLOSE_REQUEST ticks_ms=", Time.get_ticks_msec(), " unix_time=", Time.get_unix_time_from_system())

var observer: WindowObserver

func _initialize() -> void:
 auto_accept_quit = false
 print("WINDOW_DIAGNOSTIC start driver=", DisplayServer.get_name(), " ticks_ms=", Time.get_ticks_msec(), " unix_time=", Time.get_unix_time_from_system(), " auto_accept_quit=", auto_accept_quit)
 observer = WindowObserver.new()
 root.add_child(observer)
 root.close_requested.connect(_diagnostic_close_requested)
 create_timer(90.0).timeout.connect(_diagnostic_watchdog)
 super._initialize()

func _diagnostic_close_requested() -> void:
 print("WINDOW_DIAGNOSTIC signal=close_requested ticks_ms=", Time.get_ticks_msec(), " unix_time=", Time.get_unix_time_from_system())

func _diagnostic_watchdog() -> void:
 printerr("WINDOW_DIAGNOSTIC watchdog timeout: smoke did not complete; ticks_ms=", Time.get_ticks_msec())
 quit(3)
