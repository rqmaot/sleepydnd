extends Node

class Option:
	var is_some : bool
	var value
	func _init(init_some, x=null):
		is_some = init_some
		value = x
	static func Some(x) -> Option:
		return Option.new(true, x)
	static func None() -> Option:
		return Option.new(false)
