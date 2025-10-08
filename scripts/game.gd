const DEFAULT_GRID = 64.0
const DEFAULT_COLOR = Color.BLACK
const DEFAULT_THICKNESS = 1.0

class GameContents:
	class Token:
		var x : int
		var y : int
		var image : String
		func _init(x1, y1, i): 
			x = x1
			y = y1
			image = i
	class Map:
		var image : String
		var grid : float
		var color : Color
		var thickness : float
		var tokens : Array[Token]
		func _init(i, g, c, th, t):
			image = i
			grid = g
			color = c
			thickness = th
			tokens = t	
	var directory : String
	var maps : Array[Map]
	func _init(d, m):
		directory = d
		maps = m
	static func hex_to_int(hex : String) -> int:
		var n = 0
		var digits = ['0', '1', '2', '3', '4', '5', '6', '7',
					  '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']
		for c in hex:
			n *= 16
			n += digits.find(c.to_lower())
		return n
	static func hex_to_color(hex: String):
		if hex.begins_with("#"):
			hex = hex.substr(1, hex.length() - 1)
		if hex.length() != 6 and hex.length() != 8:
			return null
		var r = hex_to_int(hex.substr(0, 2))
		var g = hex_to_int(hex.substr(2, 2))
		var b = hex_to_int(hex.substr(4, 2))
		var a = 1.0 
		if hex.length() == 8:
			a = hex_to_int(hex.substr(6, 2)) / 255.0
		return Color(r, g, b, a)
	static func load_dir(dir_path : String) -> GameContents:
		var dir = DirAccess.open(dir_path)
		if dir == null: 
			print("Could not open game directory %s" % dir_path)
			return null
		if not dir.file_exists("game.json"): 
			print("%s does not contain game.json" % dir_path)
			return null
		var f = FileAccess.open(dir.get_current_dir().path_join("game.json"), FileAccess.READ)
		if f == null:
			print("Could not open game.json")
			return null
		var json = JSON.parse_string(f.get_as_text())
		if json == null: 
			print("Could not parse game.json")
			return null
		if "maps" not in json or json.maps is not Array: 
			print("game.json does not contain maps list")
			return null
		var _maps : Array[Map] = []
		var i := 0
		for map in json.maps:
			i += 1
			# check image
			if "image" not in map:
				print("image field missing from map %s" % i)
				return null
			if not dir.file_exists(map.image):
				print("Could not find %s for map image %s" % [map.image, i])
				return null
			# get grid
			var grid = DEFAULT_GRID
			if "grid" in map:
				if map.grid is not float:
					print("Failed to parse grid:%s for map %s, using default" % [map.grid, i])
				else:
					grid = map.grid
			# get color
			var color = DEFAULT_COLOR
			if "color" in map:
				var c = hex_to_color(str(map.color))
				if c == null:
					print("Failed to parse color:%s for map %i, using default" % [map.color, i])
				else:
					color = c
			# get thickness
			var thickness = DEFAULT_THICKNESS
			if "thickness" in map:
				if map.thickness is not float:
					print("Failed to parse thickness:%s for map %i, using default" % [map.thickness, i])
				else:
					thickness = map.thickness
			# get tokens
			var tokens : Array[Token] = []
			if "tokens" in map:
				if map.tokens is not Array:
					print("Invalid type for field tokens in map %s" % i)
					return null
				for t in map.tokens:
					if t is not Array or t.size() != 3 or t[0] is not float or t[1] is not float \
							or t[2] is not String:
						print("Invalid token in map %s (format is [x, y, filename])" % i)
						return null
					if not dir.file_exists(t[2]):
						print("Could not find %s for map %s" % [t[2], i])
					tokens.append(Token.new(int(t[0]), int(t[1]), t[2]))
			_maps.append(Map.new(map.image, grid, color, thickness, tokens))
		var gc = GameContents.new(dir_path, _maps)
		return gc
