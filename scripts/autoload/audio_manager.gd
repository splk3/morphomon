extends Node
## Central audio playback (autoload singleton "AudioManager").
##
## Plays looping chiptune music on the "Music" bus and one-shot sound effects on
## the "SFX" bus. Tracks are referenced by key (file name without extension) and
## loaded lazily from `res://assets/music` and `res://assets/sfx`.

const MUSIC_DIR := "res://assets/music/"
const SFX_DIR := "res://assets/sfx/"
const SFX_VOICES := 8
const MUSIC_EXTENSIONS: Array[String] = [".ogg", ".wav"]
const SFX_EXTENSIONS: Array[String] = [".wav", ".ogg"]

## Per-track loop-begin point in SECONDS. Each level theme is generated as a
## one-shot INTRO followed by the looping MIDDLE body (see tools/generate_music.py).
## Setting loop_begin past the intro makes the intro play once, then the body
## loops forever. Keep these values in sync with the generator's printed output.
## Keys not listed here loop from the start (loop_begin = 0).
const MUSIC_LOOP_BEGIN := {
	"menu_theme": 12.8000,
	"cruise_theme": 15.4839,
	"ice_theme": 14.5454,
	"lava_theme": 11.4286,
	"island_theme": 13.7143,
	"jungle_theme": 15.0000,
	"pirate_theme": 13.3333,
	"ocean_floor_theme": 15.0000,
	"space_theme": 12.3077,
	"factory_theme": 13.5211,
	"boss_theme": 10.9091,
	"credits_theme": 13.9130,
	"victory_theme": 0.0,
}

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index := 0
var _current_music_key := ""
var _music_cache: Dictionary = {}
var _sfx_cache: Dictionary = {}


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

	for i in SFX_VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)


func _load_stream(dir: String, key: String, cache: Dictionary) -> AudioStream:
	if cache.has(key):
		return cache[key]
	var path := _resolve_path(dir, key)
	if not ResourceLoader.exists(path):
		return null
	var stream: AudioStream = load(path)
	# Force music assets to loop seamlessly regardless of container format.
	if dir == MUSIC_DIR and stream is AudioStreamWAV:
		stream = stream.duplicate()
		var total_frames := int(stream.data.size() / 2)  # 16-bit mono -> 2 bytes/frame
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		# Loop from the end of the intro so the intro plays once, then the
		# MIDDLE body loops. Falls back to 0 (loop whole track) when unset.
		var loop_sec: float = MUSIC_LOOP_BEGIN.get(key, 0.0)
		var begin := int(loop_sec * stream.mix_rate)
		stream.loop_begin = clampi(begin, 0, total_frames - 1)
		stream.loop_end = total_frames
	elif dir == MUSIC_DIR and stream is AudioStreamOggVorbis:
		stream = stream.duplicate()
		var loop_sec: float = MUSIC_LOOP_BEGIN.get(key, 0.0)
		stream.loop = true
		stream.loop_offset = maxf(loop_sec, 0.0)
	cache[key] = stream
	return stream


func _resolve_path(dir: String, key: String) -> String:
	var exts: Array[String] = MUSIC_EXTENSIONS if dir == MUSIC_DIR else SFX_EXTENSIONS
	for ext: String in exts:
		var candidate: String = dir + key + ext
		if ResourceLoader.exists(candidate):
			return candidate
	return dir + key + ".wav"


func play_music(key: String) -> void:
	if key == _current_music_key and _music_player.playing:
		return
	var stream := _load_stream(MUSIC_DIR, key, _music_cache)
	if stream == null:
		return
	_current_music_key = key
	_music_player.stream = stream
	_music_player.play()


func stop_music() -> void:
	_current_music_key = ""
	_music_player.stop()


func play_sfx(key: String) -> void:
	var stream := _load_stream(SFX_DIR, key, _sfx_cache)
	if stream == null:
		return
	var player := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % SFX_VOICES
	player.stream = stream
	player.play()
