extends SceneTree
## Partite IA contro IA senza grafica: godot --headless --path . -s res://tests/sim.gd -- [partite] [livello] [due]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var games := int(args[0]) if args.size() > 0 else 3
	var lvl := int(args[1]) if args.size() > 1 else 1
	var two := args.size() > 2 and args[2] == "due"
	var wins := [0, 0, 0, 0]
	var tot := [0, 0, 0, 0]
	var t0 := Time.get_ticks_msec()
	for g in games:
		var e := WWEngine.new()
		e.headless = true
		if OS.get_environment("WW_LOG") != "":
			e.log_added.connect(func(t): print(t))
		var seats := []
		if two:
			seats = [{"name": "A", "ai": true, "level": lvl, "facs": [3, 1]}, {"name": "B", "ai": true, "level": lvl, "facs": [2, 0]}]
		else:
			for f in 4:
				seats.append({"name": "IA%d" % f, "ai": true, "level": lvl, "facs": [f]})
		e.setup({"seats": seats, "seed": 1000 + g, "opts": {"two": two, "hist": g % 2 == 1}})
		await e.run()
		var br: Dictionary = e.results["breakdown"]
		var line := "partita %d:" % g
		for f in 4:
			line += " %s %d (base %d terr %d pol %d ber %d carte %d)" % [WWData.FAC_KEY[f], br[f]["total"], br[f]["base"], br[f]["terr"], br[f]["pol"], br[f]["berlin"], br[f]["cards"]]
			tot[f] += int(br[f]["total"])
		for w in e.results["winners"]:
			wins[w] += 1
		var al := 0
		for t in WWData.T_KEY.size():
			if e.S["terr"][t]["al"]:
				al += 1
		line += " | alleati %d terr, Berlino %d, carte %d, giri %d/%d" % [al, e.berlin_count(), e.S["cards"].size(), e.S["part"], e.S["round"]]
		print(line)
	print("vittorie ", wins, " medie ", [tot[0] / games, tot[1] / games, tot[2] / games, tot[3] / games], " tempo ", Time.get_ticks_msec() - t0, " ms")
	quit()
