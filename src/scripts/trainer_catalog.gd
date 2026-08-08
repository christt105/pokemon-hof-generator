class_name TrainerCatalog
extends RefCounted

## Scans res://assets/sprites/trainers, groups the ~1500 sprites into "families"
## (e.g. brock, brock-gen1, brock-gen2, brock-lgpe -> family "brock"), and
## classifies each family into a coarse category using res://data/trainer_categories.json.

const TRAINERS_DIR := "res://assets/sprites/trainers/"
const CREDITS_PATH := "res://data/trainer_credits.json"
const CATEGORIES_PATH := "res://data/trainer_categories.json"

const CATEGORY_ORDER: Array[String] = ["protagonists", "teams", "generic", "characters"]
const CATEGORY_LABELS := {
	"protagonists": "Protagonistas",
	"teams": "Equipos",
	"generic": "Entrenadores",
	"characters": "Personajes",
}

# Strips known redraw/variant suffixes (gen1, masters2, anime, contest, league...)
# so different art versions of the same character collapse into one family.
const _VARIANT_SUFFIX_PATTERN := "-(gen\\d\\w*|masters\\d?|anime\\d?|isekai|lgpe|usum|rse|dp|xy|shuffle|cook\\d?|snow\\w*|unmasked|champion\\w*|two|contest|league|dojo|tundra|casual|festival|pokestar\\d?|wonderlauncher|radar|stance|zerosuit|professor|leader|boss|unite|conquest|e|rs|jp|ai|pwt|nihilego|ginkgo|flipped|stand|master|s|v|\\d)$"

var _variant_regex := RegEx.new()
var _family_category: Dictionary = {}  # family_key -> category
var _credits: Dictionary = {}


func _init() -> void:
	_variant_regex.compile(_VARIANT_SUFFIX_PATTERN)
	_credits = _load_json_dict(CREDITS_PATH)

	var raw_categories := _load_json_dict(CATEGORIES_PATH)
	for category: String in raw_categories.keys():
		for family_key: String in raw_categories[category]:
			_family_category[family_key] = category


## Returns families sorted by display name, each a Dictionary:
## { key, category, display_name, variants: [{ file, path, display_name, credit }] }
func load_families() -> Array[Dictionary]:
	var dir := DirAccess.open(TRAINERS_DIR)
	if dir == null:
		printerr("TrainerCatalog: could not open %s" % TRAINERS_DIR)
		return []

	var by_family: Dictionary = {}  # family_key -> Array[String] (filename stems)
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			var stem := file_name.get_basename()
			var family_key := _family_key(stem)
			if not by_family.has(family_key):
				by_family[family_key] = []
			by_family[family_key].append(stem)
		file_name = dir.get_next()
	dir.list_dir_end()

	var families: Array[Dictionary] = []
	for family_key: String in by_family.keys():
		var stems: Array = by_family[family_key]
		stems.sort_custom(func(a: String, b: String) -> bool:
			if a == family_key:
				return true
			if b == family_key:
				return false
			return a < b
		)

		var variants: Array[Dictionary] = []
		for stem: String in stems:
			var filename := "%s.png" % stem
			variants.append({
				"file": filename,
				"path": TRAINERS_DIR + filename,
				"display_name": _humanize(stem),
				"credit": _credits.get(filename, ""),
			})

		families.append({
			"key": family_key,
			"category": _family_category.get(family_key, "characters"),
			"display_name": _humanize(family_key),
			"variants": variants,
		})

	families.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["display_name"].naturalnocasecmp_to(b["display_name"]) < 0
	)
	return families


func _family_key(stem: String) -> String:
	var key := stem
	var changed := true
	while changed:
		changed = false
		var m := _variant_regex.search(key)
		if m:
			var stripped := key.substr(0, m.get_start())
			if stripped != "":
				key = stripped
				changed = true
	return key


func _humanize(key: String) -> String:
	var words := key.replace("-", " ").replace("_", " ").split(" ", false)
	var out := PackedStringArray()
	for w: String in words:
		out.append(w[0].to_upper() + w.substr(1))
	return " ".join(out)


func _load_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
