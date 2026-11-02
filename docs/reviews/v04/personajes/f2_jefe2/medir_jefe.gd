extends SceneTree
## Mide el jefe: bbox de píxeles opacos del preview, con todo y sin la grúa (poste, balancín, cadenas, contrapeso).
const CRANE := ["post_bar", "post_foot", "post_fork", "beam_bar", "beam_cap_l", "beam_cap_r", "beam_pin", "beam_riv_0", "beam_riv_1",
	"beam_riv_2", "beam_riv_3", "strut_riv", "strut", "weight", "weight_band", "weight_ring", "weight_riv", "cw_snap_end",
	"weight_ground", "weight_ground_band"]

func _bbox(img: Image) -> Rect2i:
	var x0 := 9999; var y0 := 9999; var x1 := -1; var y1 := -1
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				x0 = mini(x0, x); y0 = mini(y0, y); x1 = maxi(x1, x); y1 = maxi(y1, y)
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)

func _init() -> void:
	var def: RigDef = load("res://scripts/art/defs/bosses/great_bellows.gd").build()
	for v in [[&"base", {&"whole": true}], [&"phase2", {&"broken": true}]]:
		for anim in [&"idle"]:
			var a: RigDef.Anim = def.anims[anim]
			for f in a.frames:
				var pose := RigPose.sample(a, float(f))
				var full := RigRenderer.render_pose(def, pose, v[1]).preview
				var p2 := pose.duplicate()
				for id: String in CRANE:
					p2[StringName("hide:" + id)] = true
				for i in 15:
					p2[StringName("hide:rod_link_%d" % i)] = true
				for i in 8:
					p2[StringName("hide:cw_link_%d" % i)] = true
				for i in 3:
					p2[StringName("hide:cw_snap_%d" % i)] = true
				var body := RigRenderer.render_pose(def, p2, v[1]).preview
				var bf := _bbox(full); var bb := _bbox(body)
				print("MEDIDA %s %s f%d total=%dx%d (x%d-%d y%d-%d) cuerpo=%dx%d (x%d-%d y%d-%d)" % [v[0], anim, f, bf.size.x, bf.size.y,
					bf.position.x, bf.end.x - 1, bf.position.y, bf.end.y - 1, bb.size.x, bb.size.y, bb.position.x, bb.end.x - 1, bb.position.y, bb.end.y - 1])
	quit()
