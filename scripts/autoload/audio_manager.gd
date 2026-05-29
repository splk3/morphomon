extends Node
## Central audio playback (autoload singleton "AudioManager").
##
## Plays looping chiptune music on the "Music" bus and one-shot sound effects on
## the "SFX" bus. Tracks are referenced by key (file name without extension) and
## loaded lazily from `res://assets/music` and `res://assets/sfx`.

const MUSIC_DIR := "res://assets/music/"
const SFX_DIR := "res://assets/sfx/"
const SFX_VOICES := 8

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
	var path := dir + key + ".wav"
	if not ResourceLoader.exists(path):
		return null
	var stream: AudioStream = load(path)
	# Imported WAVs default to no looping; force music to loop seamlessly.
	if stream is AudioStreamWAV and dir == MUSIC_DIR:
		stream = stream.duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.data.size() / 2  # 16-bit mono -> 2 bytes/frame
	cache[key] = stream
	return stream


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
