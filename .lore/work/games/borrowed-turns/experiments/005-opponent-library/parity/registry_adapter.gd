extends RefCounted

const Encounters = preload("res://content/encounters.gd")

func fixture(id: String) -> Dictionary:
	return Encounters.registry()[id].data
