@tool
extends EditorScript

# Run from the Script Editor (File > Run, or Ctrl+Shift+X) with this script open.
# Downloads any trainer sprite from Pokemon Showdown that isn't already in
# LOCAL_DIR, and writes a filename -> credit map for the credited sprites to CREDITS_PATH.

const HOST := "play.pokemonshowdown.com"
const LIST_PATH := "/sprites/trainers/?view=sprites"
const SPRITE_PATH_PREFIX := "/sprites/trainers/"
const LOCAL_DIR := "res://assets/sprites/trainers/"
const CREDITS_PATH := "res://data/trainer_credits.json"

# Matches each <figure id="name.png">...<figcaption><a ...>name</a>[<br />by credit]</figcaption></figure> block.
const FIGURE_PATTERN := '<figure id="([^"]+)">\\s*<img[^>]*src="([^"]+)"[^>]*/>\\s*<figcaption><a href="[^"]+">([^<]+)</a>(?:<br\\s*/>\\s*by\\s+([^<]+))?</figcaption>\\s*</figure>'

func _run() -> void:
	var client := HTTPClient.new()
	if _connect(client) != OK:
		printerr("Could not connect to %s" % HOST)
		return

	print("Fetching sprite list from %s%s ..." % [HOST, LIST_PATH])
	var html := _get_bytes(client, LIST_PATH).get_string_from_utf8()
	if html.is_empty():
		printerr("Failed to fetch sprite listing")
		return

	var entries := _parse_sprites(html)
	if entries.is_empty():
		printerr("No sprites found — the Showdown page format may have changed")
		return
	print("Found %d sprites on Showdown" % entries.size())

	DirAccess.make_dir_recursive_absolute(LOCAL_DIR)
	DirAccess.make_dir_recursive_absolute(CREDITS_PATH.get_base_dir())

	var credits := {}
	var downloaded := 0
	var skipped := 0
	var failed := 0

	for entry in entries:
		var filename: String = entry.filename
		if entry.credit != "":
			credits[filename] = entry.credit

		var local_path := LOCAL_DIR + filename
		if FileAccess.file_exists(local_path):
			skipped += 1
			continue

		var bytes := _get_bytes(client, SPRITE_PATH_PREFIX + filename)
		if bytes.is_empty() and client.get_status() != HTTPClient.STATUS_CONNECTED:
			# Connection dropped (Showdown closes idle keep-alives); reconnect and retry once.
			if _connect(client) == OK:
				bytes = _get_bytes(client, SPRITE_PATH_PREFIX + filename)

		if bytes.is_empty():
			printerr("Failed to download %s" % filename)
			failed += 1
			continue

		var file := FileAccess.open(local_path, FileAccess.WRITE)
		if file == null:
			printerr("Could not write %s (error %d)" % [local_path, FileAccess.get_open_error()])
			failed += 1
			continue
		file.store_buffer(bytes)
		file.close()
		downloaded += 1
		if downloaded % 25 == 0:
			print("Downloaded %d sprites..." % downloaded)

	var credits_file := FileAccess.open(CREDITS_PATH, FileAccess.WRITE)
	credits_file.store_string(JSON.stringify(credits, "\t"))
	credits_file.close()

	print("Done. Downloaded: %d | already present: %d | failed: %d | total tracked: %d" % [downloaded, skipped, failed, entries.size()])
	print("Credits written to %s (%d credited sprites)" % [CREDITS_PATH, credits.size()])

	if downloaded > 0:
		EditorInterface.get_resource_filesystem().scan()


func _connect(client: HTTPClient) -> Error:
	var err := client.connect_to_host(HOST, 443, TLSOptions.client())
	if err != OK:
		return err
	while client.get_status() == HTTPClient.STATUS_CONNECTING or client.get_status() == HTTPClient.STATUS_RESOLVING:
		client.poll()
		OS.delay_msec(10)
	return OK if client.get_status() == HTTPClient.STATUS_CONNECTED else FAILED


func _get_bytes(client: HTTPClient, path: String) -> PackedByteArray:
	var err := client.request(HTTPClient.METHOD_GET, path, ["User-Agent: pokemon-hof-generator-sprite-sync"])
	if err != OK:
		printerr("Request error for %s: %d" % [path, err])
		return PackedByteArray()

	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll()
		OS.delay_msec(5)

	if client.get_response_code() != 200:
		printerr("HTTP %d for %s" % [client.get_response_code(), path])

	var body := PackedByteArray()
	while client.get_status() == HTTPClient.STATUS_BODY:
		client.poll()
		var chunk := client.read_response_body_chunk()
		if chunk.size() == 0:
			OS.delay_msec(5)
		else:
			body.append_array(chunk)

	return body


func _parse_sprites(html: String) -> Array:
	var regex := RegEx.new()
	regex.compile(FIGURE_PATTERN)
	var results := []
	for m in regex.search_all(html):
		results.append({
			"filename": m.get_string(1).strip_edges(),
			"credit": m.get_string(4).strip_edges(),
		})
	return results
