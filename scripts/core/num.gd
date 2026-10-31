class_name Num
extends RefCounted
## Formateo de números grandes para la economía incremental.

const SUFFIXES: Array[String] = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]


static func fmt(x: float) -> String:
	if is_nan(x) or is_inf(x):
		return "∞"
	var sign_str := "-" if x < 0.0 else ""
	x = absf(x)
	if x < 1000.0:
		if x < 10.0 and x != floorf(x):
			return sign_str + ("%.1f" % x)
		return sign_str + str(int(floorf(x)))
	var tier := int(floorf(log(x) / log(1000.0)))
	if tier >= SUFFIXES.size():
		return sign_str + ("%.2e" % x).replace("e+", "e")
	var scaled := x / pow(1000.0, tier)
	var digits := "%.2f" if scaled < 10.0 else ("%.1f" if scaled < 100.0 else "%.0f")
	return sign_str + (digits % scaled) + SUFFIXES[tier]


static func fmt_time(seconds: float) -> String:
	var s := int(seconds)
	if s < 60:
		return "%ds" % s
	if s < 3600:
		return "%dm %02ds" % [s / 60, s % 60]
	return "%dh %02dm" % [s / 3600, (s % 3600) / 60]
