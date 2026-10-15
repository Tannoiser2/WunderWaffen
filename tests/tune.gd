extends SceneTree
## Confronto di pesi dell'IA: godot --headless --path . -s res://tests/tune.gd -- <partite> '<json pesi alleati>' '<json pesi tedesco>'
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var games := int(a[0]) if a.size() > 0 else 6
	var wa = JSON.parse_string(a[1]) if a.size() > 1 else {}
	var wg = JSON.parse_string(a[2]) if a.size() > 2 else {}
	var tot := [0, 0, 0, 0]
	var wins := [0, 0, 0, 0]
	var conq := 0
	var ber := 0
	for g in games:
		var e := WWEngine.new()
		e.headless = true
		var seats := []
		for f in 4:
			seats.append({"name": "IA%d" % f, "ai": true, "level": 1, "facs": [f]})
		e.setup({"seats": seats, "seed": 5000 + g, "opts": {"hist": g % 2 == 1}})
		for s in 4:
			e.ais[s].set_weights(wg if s == 0 else wa)
		await e.run()
		for f in 4:
			tot[f] += int(e.results["breakdown"][f]["total"])
		for w in e.results["winners"]:
			wins[w] += 1
		for t in WWData.T_KEY.size():
			if e.S["terr"][t]["al"]:
				conq += 1
		ber += e.berlin_count()
	print("vittorie ", wins, " medie ", [tot[0] / games, tot[1] / games, tot[2] / games, tot[3] / games], " territori alleati %.1f Berlino %.1f" % [float(conq) / games, float(ber) / games])
	quit()
