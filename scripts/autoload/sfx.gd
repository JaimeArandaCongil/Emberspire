extends Node
## Sfx: audio 100% sintetizado al arrancar (sin binarios en el repo).
## Efectos chiptune y dos bucles musicales (Forja / Torre).

const RATE := 22050
const VOICES := 10

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _music_id := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	_build()


func play(id: String, pitch_jitter := 0.06, volume_db := 0.0) -> void:
	if not _streams.has(id):
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _streams[id]
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.volume_db = volume_db + linear_to_db(maxf(Game.sfx_volume, 0.0001))
	p.play()


func music(id: String) -> void:
	if id == _music_id:
		return
	_music_id = id
	if not _streams.has("music_" + id):
		_music.stop()
		return
	_music.stream = _streams["music_" + id]
	_music.volume_db = linear_to_db(maxf(Game.music_volume * 0.6, 0.0001))
	_music.play()


func refresh_volume() -> void:
	_music.volume_db = linear_to_db(maxf(Game.music_volume * 0.6, 0.0001))


# --- Síntesis -------------------------------------------------------------

func _build() -> void:
	_streams["click"] = _tone([[880.0, 0.03], [660.0, 0.03]], "square", 0.25)
	_streams["hover"] = _tone([[1320.0, 0.02]], "square", 0.08)
	_streams["card"] = _noise(0.09, 0.35, 4000.0, 900.0)
	_streams["hit"] = _mix(_noise(0.12, 0.6, 2500.0, 200.0), _tone([[140.0, 0.1]], "square", 0.35))
	_streams["heavy"] = _mix(_noise(0.25, 0.8, 1800.0, 80.0), _sweep(160.0, 50.0, 0.25, "square", 0.5))
	_streams["block"] = _mix(_tone([[1200.0, 0.12]], "sine", 0.25), _tone([[1810.0, 0.1]], "sine", 0.18))
	_streams["burn"] = _mix(_noise(0.45, 0.5, 600.0, 5000.0), _sweep(200.0, 700.0, 0.35, "triangle", 0.25))
	_streams["coin"] = _tone([[1320.0, 0.05], [1760.0, 0.09]], "square", 0.2)
	_streams["buy"] = _tone([[523.0, 0.05], [659.0, 0.05], [784.0, 0.05], [1046.0, 0.1]], "square", 0.22)
	_streams["deny"] = _tone([[180.0, 0.08], [140.0, 0.1]], "square", 0.25)
	_streams["heal"] = _sweep(400.0, 1200.0, 0.3, "sine", 0.3)
	_streams["debuff"] = _sweep(700.0, 200.0, 0.25, "square", 0.2)
	_streams["buff"] = _sweep(300.0, 900.0, 0.2, "square", 0.2)
	_streams["death"] = _mix(_noise(0.5, 0.6, 1500.0, 60.0), _sweep(300.0, 40.0, 0.5, "square", 0.35))
	_streams["victory"] = _tone([[523.0, 0.1], [659.0, 0.1], [784.0, 0.1], [1046.0, 0.3]], "square", 0.25)
	_streams["defeat"] = _tone([[392.0, 0.18], [330.0, 0.18], [262.0, 0.18], [196.0, 0.5]], "triangle", 0.35)
	_streams["turn"] = _tone([[660.0, 0.04], [990.0, 0.06]], "triangle", 0.25)
	_streams["door"] = _mix(_noise(0.3, 0.3, 300.0, 120.0), _sweep(90.0, 60.0, 0.3, "square", 0.3))
	_streams["rebirth"] = _mix(_sweep(100.0, 1600.0, 1.2, "triangle", 0.35), _noise(1.2, 0.25, 300.0, 6000.0))
	_streams["music_forge"] = _song([57, 60, 64, 62, 57, 60, 65, 64], [45, 45, 41, 43], 76.0, 0.11)
	_streams["music_tower"] = _song([57, 60, 57, 63, 62, 60, 58, 57, 55, 58, 62, 60], [45, 45, 43, 42], 112.0, 0.10)


func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = samples.size()
	return s


static func _osc(kind: String, phase: float) -> float:
	match kind:
		"square": return 1.0 if fposmod(phase, 1.0) < 0.5 else -1.0
		"triangle": return 4.0 * absf(fposmod(phase, 1.0) - 0.5) - 1.0
		"saw": return 2.0 * fposmod(phase, 1.0) - 1.0
	return sin(phase * TAU)


func _tone(notes: Array, kind: String, vol: float) -> AudioStreamWAV:
	var out := PackedFloat32Array()
	for n: Array in notes:
		var freq: float = n[0]
		var count := int(float(n[1]) * RATE)
		var phase := 0.0
		for i in count:
			var env := minf(1.0, i / 60.0) * (1.0 - float(i) / count)
			out.append(_osc(kind, phase) * env * vol)
			phase += freq / RATE
	return _wav(out)


func _sweep(f0: float, f1: float, dur: float, kind: String, vol: float) -> AudioStreamWAV:
	var out := PackedFloat32Array()
	var count := int(dur * RATE)
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		out.append(_osc(kind, phase) * (1.0 - t) * minf(1.0, i / 60.0) * vol)
		phase += lerpf(f0, f1, t) / RATE
	return _wav(out)


func _noise(dur: float, vol: float, cut0: float, cut1: float) -> AudioStreamWAV:
	var out := PackedFloat32Array()
	var count := int(dur * RATE)
	var y := 0.0
	for i in count:
		var t := float(i) / count
		var cut := lerpf(cut0, cut1, t)
		var a := clampf(cut / RATE * TAU, 0.0, 1.0)
		y += a * (randf_range(-1.0, 1.0) - y)
		out.append(y * vol * pow(1.0 - t, 1.5) * 2.0)
	return _wav(out)


func _mix(a: AudioStreamWAV, b: AudioStreamWAV) -> AudioStreamWAV:
	var n := maxi(a.data.size(), b.data.size()) / 2
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var va := a.data.decode_s16(i * 2) / 32000.0 if i * 2 < a.data.size() else 0.0
		var vb := b.data.decode_s16(i * 2) / 32000.0 if i * 2 < b.data.size() else 0.0
		out[i] = (va + vb) * 0.8
	return _wav(out)


static func _midi(n: float) -> float:
	return 440.0 * pow(2.0, (n - 69.0) / 12.0)


## Bucle: arpegio triangular + bajo cuadrado + pulso de ruido suave.
func _song(melody: Array, bass: Array, bpm: float, vol: float) -> AudioStreamWAV:
	var beat := 60.0 / bpm
	var step := beat / 2.0
	var bars := 4
	var steps_total := bars * 8
	var total := int(steps_total * step * RATE)
	var out := PackedFloat32Array()
	out.resize(total)
	var step_len := int(step * RATE)
	for s in steps_total:
		var bar := s / 8
		var note: float = melody[s % melody.size()] + (12.0 if (s / melody.size()) % 2 == 1 and s % 3 == 0 else 0.0)
		var f := _midi(note)
		var fb := _midi(float(bass[bar % bass.size()]))
		var phase := 0.0
		var phase_b := 0.0
		for i in step_len:
			var idx := s * step_len + i
			if idx >= total:
				break
			var t := float(i) / step_len
			var env := minf(1.0, i / 80.0) * pow(1.0 - t, 1.6)
			var v := _osc("triangle", phase) * env * vol
			v += _osc("square", phase_b) * 0.35 * vol * (0.6 + 0.4 * (1.0 - t))
			if s % 4 == 2 and i < 900:
				v += randf_range(-1.0, 1.0) * 0.05 * (1.0 - i / 900.0)
			out[idx] = v
			phase += f / RATE
			phase_b += fb / RATE
	return _wav(out, true)
