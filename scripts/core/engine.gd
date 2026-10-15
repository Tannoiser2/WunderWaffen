class_name WWEngine
extends RefCounted
## Motore delle regole di WunderWaffen (regolamento italiano 2025, Oliphante).
## Lo stato della partita sta tutto nel dizionario S, così l'IA può copiarlo e provare le mosse
## su una copia (sim = true: niente attese, le scelte le fa subito la politica dell'IA).
## Ogni scelta passa da decide(): in locale la fa la persona o l'IA, online passa dal registro mosse.

signal changed
signal log_added(text: String)
signal decision_requested(req: Dictionary)
signal decision_provided(result)
signal game_ended(results: Dictionary)
signal fx(kind: String, data: Dictionary)

const D = preload("res://scripts/data/ww_data.gd")
const GER := 0

var S := {}
var rng := RandomNumberGenerator.new()
var host: Node                      # nodo che fornisce i timer (la vista di gioco)
var ai_delay := 0.0
var headless := false
var sim := false                    # copia di prova dell'IA
var sim_policy: Callable            # (eng, fac, req) -> risposta, usata quando sim = true
var abort := false
var online = null
var ais := {}                       # posto -> WWAI
var seats: Array = []               # {name, ai, level, facs:[...]}
var seat_of := [0, 0, 0, 0]         # fazione -> posto
var opts := {}
var log_lines: Array = []
var results := {}


# ------------------------------------------------------------------ preparazione

## config: {"seats":[{"name","ai","level","facs":[...]}], "seed", "opts":{"two","hist","nocards"}}
func setup(config: Dictionary) -> void:
	if config.has("seed"):
		rng.seed = int(config["seed"])
	else:
		rng.randomize()
	opts = config.get("opts", {}).duplicate()
	ai_delay = float(config.get("ai_delay", 0.0))
	seats = []
	for st in config["seats"]:
		seats.append({"name": str(st["name"]), "ai": bool(st["ai"]), "level": int(st.get("level", 1)),
			"facs": (st["facs"] as Array).duplicate()})
	for s in seats.size():
		for f in seats[s]["facs"]:
			seat_of[int(f)] = s
		var a := WWAI.new()
		a.level = seats[s]["level"]
		a.rng.seed = rng.seed + 7919 * (s + 1)
		ais[s] = a
	S = {
		"part": 1, "round": 0, "first": 0, "cur": -1, "step": 0,
		"pv": [0, 0, 0, 0], "mor": [0, 0, 0, 0], "pol": [0, 0, 0, 0], "mst": [0, 0, 0, 0], "pst": [0, 0, 0, 0],
		"stamp": 0, "eve": [0, 0, 0, 0], "ric": 0,
		"loc": [], "start": [[], [], [], []],
		"terr": [], "ber": [null, null, null, null, null, null], "berx": [],
		"conf": [null, null, null], "conf_closed": false,
		"tiles": [[], [], [], []], "cards": [], "cdisp": [[], [], []], "cdeck": [[], [], []], "cgone": [],
		"bought": false, "ber_full": false, "over": false, "spied": [],
	}
	for i in 72:
		S["loc"].append("res")
	# segnalini: Politica in ordine casuale, Morale in ordine inverso
	var order := [0, 1, 2, 3]
	_shuffle(order)
	for k in 4:
		S["pst"][order[k]] = k + 1
		S["mst"][order[k]] = 4 - k
	S["stamp"] = 10
	# tessere Territorio
	var tiles := []
	for i in 24:
		tiles.append(i)
	_shuffle(tiles)
	for t in D.T_KEY.size():
		var tile := -1
		if t != D.BERLIN:
			tile = int(D.HIST_TILES[t]) if opts.get("hist", false) else int(tiles.pop_back())
		S["terr"].append({"sl": [null, null, null], "cp": null, "al": false, "fort": false, "ctrl": GER,
			"tile": tile, "share": []})
	# carte Ricerca
	for i in D.CARDS.size():
		S["cdeck"][int(D.CARDS[i]["lvl"]) - 1].append(i)
	for l in 3:
		_shuffle(S["cdeck"][l])
		for k in 4:
			S["cdisp"][l].append(S["cdeck"][l].pop_back())
	S["first"] = D.ORDER[rng.randi() % 4]


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


## Copia per le prove dell'IA: stesso stato, nessun segnale verso la vista, nessuna attesa.
func clone_sim(policy: Callable) -> WWEngine:
	var e := WWEngine.new()
	e.S = S.duplicate(true)
	e.rng.seed = rng.seed
	e.rng.state = rng.state
	e.sim = true
	e.headless = true
	e.sim_policy = policy
	e.opts = opts
	e.seats = seats
	e.seat_of = seat_of
	return e


func pname(f: int) -> String:
	if f < 0 or f > 3:
		return "?"
	var s: Dictionary = seats[seat_of[f]] if seats.size() > seat_of[f] else {}
	if s.is_empty() or s["ai"] or str(s["name"]) == D.FAC_NAME[f] or str(s["name"]).begins_with("Giocatore"):
		return D.FAC_NAME[f]
	return "%s (%s)" % [D.FAC_NAME[f], s["name"]]


func log_msg(t: String) -> void:
	if sim:
		return
	log_lines.append(t)
	log_added.emit(t)


func is_ai(f: int) -> bool:
	return seats[seat_of[f]]["ai"]


func any_local_human() -> bool:
	for s in seats.size():
		if not seats[s]["ai"] and (online == null or s == online.seat):
			return true
	return false


func two() -> bool:
	return opts.get("two", false)


func team_of(f: int) -> int:
	return 0 if (f == D.UK or f == D.USSR) else 1


## Fazioni alleate colpite dalle carte tedesche (nella partita a due gli americani sono esclusi).
func card_allies() -> Array:
	return [D.USSR, D.UK] if two() else [D.USSR, D.USA, D.UK]


# ------------------------------------------------------------------ decisioni

func decide(f: int, req: Dictionary):
	req["fac"] = f
	if sim:
		return sim_policy.call(self, f, req)
	var seat: int = seat_of[f]
	req["seat"] = seat
	S["cur_dec"] = f
	if abort:
		return ais[seat].decide(self, f, req)
	if online != null:
		return await online.decide(self, seat, req)
	if seats[seat]["ai"]:
		await _wait(ai_delay)
		return ais[seat].decide(self, f, req)
	decision_requested.emit(req)
	var r = await decision_provided
	return r


func _int(r, def: int) -> int:
	if r is int or r is float:
		return int(r)
	return def


func provide_decision(r) -> void:
	decision_provided.emit(r)


func _wait(sec: float) -> void:
	if sim or headless or abort or sec <= 0.0 or host == null or not host.is_inside_tree():
		return
	if online != null and online.catchup:
		return
	await host.get_tree().create_timer(sec).timeout


func _fx(kind: String, data: Dictionary) -> void:
	if not sim:
		fx.emit(kind, data)


# ------------------------------------------------------------------ interrogazioni

func ptype(pid: int, back: bool) -> int:
	return int(D.P_BACK[pid]) if back else int(D.P_FRONT[pid])


func reserve(f: int) -> Array:
	var out := []
	for k in 18:
		var p := f * 18 + k
		if S["loc"][p] == "res":
			out.append(p)
	return out


func discards(f: int) -> Array:
	var out := []
	for k in 18:
		var p := f * 18 + k
		if S["loc"][p] == "disc":
			out.append(p)
	return out


func reserve_types(f: int) -> Dictionary:
	var c := {}
	for p in reserve(f):
		var t := int(D.P_FRONT[p])
		c[t] = int(c.get(t, 0)) + 1
	return c


func has_card(key: String) -> bool:
	for c in S["cards"]:
		if D.CARDS[c]["key"] == key:
			return true
	return false


func berlin_count() -> int:
	var n := 0
	for b in S["ber"]:
		if b != null:
			n += 1
	return n


## Territori controllati (per il punteggio): agli Alleati quelli conquistati, al tedesco tutto il resto
## (Berlino resta tedesca finché ha almeno una casella libera).
func controlled(f: int) -> int:
	var n := 0
	for t in D.T_KEY.size():
		var T: Dictionary = S["terr"][t]
		if t == D.BERLIN:
			if f == GER and berlin_count() < 6:
				n += 1
			continue
		if f == GER:
			if not T["al"]:
				n += 1
		elif T["al"] and int(T["ctrl"]) == f:
			n += 1
	return n


func allied_around_berlin() -> int:
	var n := 0
	for a in D.T_ADJ[D.BERLIN]:
		if S["terr"][a]["al"]:
			n += 1
	return n


## L'Alleato f può giocare nel territorio t: adiacente alla sua area di partenza, a un suo
## territorio o a un territorio condiviso con una sua pedina Politica.
func access(f: int, t: int) -> bool:
	if f == GER:
		return true
	if t in D.START_ADJ[f]:
		return true
	for a in D.T_ADJ[t]:
		var A: Dictionary = S["terr"][a]
		if A["al"] and int(A["ctrl"]) == f:
			return true
		for sh in A["share"]:
			if int(sh["f"]) == f:
				return true
	return false


func strength_for(f: int, t: int) -> int:
	var s: int = D.STRENGTH[t]
	if f == GER and t == D.FAN and has_card("mecc"):
		s = 2
	return s


func can_place(f: int, s: int, t: int, i: int) -> bool:
	if t == D.BERLIN or s <= 0:
		return false
	var T: Dictionary = S["terr"][t]
	if T["al"]:
		return false
	if f == GER:
		if T["fort"]:
			return false
	elif not access(f, t):
		return false
	var occ = T["sl"][i]
	if occ == null:
		return s >= int(D.T_SLOTS[t][i])
	var of := int(occ["f"])
	if f == GER:
		return of != GER and s > int(occ["s"])
	return of == GER and s >= int(occ["s"])


func next_event_box(f: int) -> int:
	return mini(int(S["eve"][f]) + 1, 6)


## Tutti gli usi possibili di una pedina giocata da f (back = ricevuta girata sul retro).
func legal_uses(f: int, pid: int, back: bool) -> Array:
	var t := ptype(pid, back)
	var out := []
	var s := strength_for(f, t)
	if s > 0:
		for tid in D.T_KEY.size():
			if tid == D.BERLIN:
				continue
			for i in 3:
				if can_place(f, s, tid, i):
					out.append({"a": "place", "t": tid, "i": i})
	if f != GER:
		# Berlino
		if not back and t in [D.COR, D.SIM, D.POL] and allied_around_berlin() >= 4 and access(f, D.BERLIN):
			var free := false
			for i in 6:
				if S["ber"][i] == null:
					out.append({"a": "berlin", "i": i})
					free = true
			if not free:
				out.append({"a": "berlin", "i": 5})
		if t in [D.POL, D.SIM]:
			# territorio condiviso
			for tid in D.T_KEY.size():
				var T: Dictionary = S["terr"][tid]
				if T["al"] and int(T["ctrl"]) != f and access(f, tid):
					var mine := false
					for sh in T["share"]:
						if int(sh["f"]) == f:
							mine = true
					if not mine:
						out.append({"a": "share", "t": tid})
			# Conferenza
			if not S["conf_closed"]:
				var inside := false
				for c in S["conf"]:
					if c != null and int(c["f"]) == f:
						inside = true
				if not inside:
					for i in 3:
						if S["conf"][i] == null:
							out.append({"a": "conf", "i": i})
			out.append({"a": "pol"})
		if t in [D.MOR, D.SIM]:
			out.append({"a": "mor"})
		var box := next_event_box(f)
		var req: Array = D.EVENTS[f][box - 1]["req"]
		if t == D.EVE or t == D.SIM or t in req:
			out.append({"a": "eve"})
		if t in [D.AVI, D.SIM] and int(S["ric"]) > 0:
			out.append({"a": "ricback"})
	else:
		if t in [D.MOR, D.MOR2, D.SIM]:
			out.append({"a": "mor"})
		if t in [D.RIC, D.RIC2, D.SIM]:
			out.append({"a": "ric"})
	if out.is_empty():
		out.append({"a": "discard"})
	return out


## A chi si può dare il retro della pedina (vuoto = non si può dare).
func gift_targets(f: int, pid: int) -> Array:
	var to: Array = D.P_BACK_TO[pid]
	var out := []
	if int(to[0]) == -1:
		out = [D.USSR, D.USA, D.UK]
	else:
		for x in to:
			out.append(int(x))
	var res := []
	for x in out:
		if x == f:
			continue
		if two() and team_of(x) == team_of(f):
			continue
		res.append(x)
	return res


func card_cost(c: int) -> int:
	var cd: Dictionary = D.CARDS[c]
	var v := int(cd["lvl"])
	if has_card("braun") and (int(cd["atom"]) > 0 or int(cd["rocket"]) > 0):
		v -= 1
	return maxi(v, 0)


func atoms() -> int:
	var n := 0
	for c in S["cards"]:
		n += int(D.CARDS[c]["atom"])
	return n


func buyable() -> Array:
	var pts: int = D.RIC_POINTS[int(S["ric"])]
	var out := []
	if pts <= 0:
		return out
	for l in 3:
		for c in S["cdisp"][l]:
			if card_cost(c) <= pts and (D.CARDS[c]["key"] != "atomica" or atoms() >= 3):
				out.append(c)
	return out


## Chi vince la casella più alta di Politica (in parità, il segnalino più in alto).
func politics_leader() -> int:
	var best := -1
	for f in 4:
		if best < 0 or int(S["pol"][f]) > int(S["pol"][best]) or (int(S["pol"][f]) == int(S["pol"][best]) and int(S["pst"][f]) > int(S["pst"][best])):
			best = f
	return best


func _pol_better(a: int, b: int) -> bool:
	if int(S["pol"][a]) != int(S["pol"][b]):
		return int(S["pol"][a]) > int(S["pol"][b])
	return int(S["pst"][a]) > int(S["pst"][b])


# ------------------------------------------------------------------ tracciati

func gain_pv(f: int, d: int) -> void:
	S["pv"][f] = maxi(0, int(S["pv"][f]) + d)


func _stamp() -> int:
	S["stamp"] = int(S["stamp"]) + 1
	return int(S["stamp"])


func gain_mor(f: int, d: int) -> void:
	_track("mor", "mst", f, d)


func gain_pol(f: int, d: int) -> void:
	_track("pol", "pst", f, d)


func _track(k: String, st: String, f: int, d: int) -> void:
	if d > 0:
		for n in d:
			if int(S[k][f]) >= 4:
				for g in 4:
					if g != f and int(S[k][g]) > 0:
						S[k][g] = int(S[k][g]) - 1
						S[st][g] = _stamp()
			else:
				S[k][f] = int(S[k][f]) + 1
			S[st][f] = _stamp()
	elif d < 0:
		for n in -d:
			if int(S[k][f]) == 0:
				gain_pv(f, -2)
			else:
				S[k][f] = int(S[k][f]) - 1
				S[st][f] = _stamp()


func gain_ric(d: int) -> void:
	S["ric"] = clampi(int(S["ric"]) + d, 0, D.RIC_MAX)


## Dopo ogni guadagno di Ricerca il tedesco può comprare subito una carta (una per turno).
func maybe_buy() -> void:
	if S["bought"] or S["over"]:
		return
	var opts_c := buyable()
	if opts_c.is_empty():
		return
	var r = await decide(GER, {"type": "buy", "options": opts_c})
	var c := int(r) if (r is int or r is float) else -1
	if c in opts_c:
		await acquire(c, true)


func _refill(l: int) -> void:
	while S["cdisp"][l].size() < 4 and not S["cdeck"][l].is_empty():
		S["cdisp"][l].append(S["cdeck"][l].pop_back())


func _take_from_display(c: int) -> void:
	var l := int(D.CARDS[c]["lvl"]) - 1
	S["cdisp"][l].erase(c)
	_refill(l)


## Il tedesco acquisisce una carta (con i punti Ricerca o gratis da una tessera).
func acquire(c: int, research: bool) -> void:
	var cd: Dictionary = D.CARDS[c]
	_take_from_display(c)
	S["cards"].append(c)
	if research:
		if int(S["ric"]) >= D.RIC_MAX:
			gain_pv(GER, 5)
			log_msg("Il tracciato Ricerca era completo: il tedesco ottiene anche 5 PV.")
		S["ric"] = 0
		S["bought"] = true
	log_msg("Il tedesco acquisisce la carta Ricerca «%s»." % cd["name"])
	_fx("card", {"c": c})
	if int(cd["pv"]) > 0:
		gain_pv(GER, int(cd["pv"]))
	if int(cd["pol"]) > 0:
		gain_pol(GER, int(cd["pol"]))
	if int(cd["mor"]) > 0:
		gain_mor(GER, int(cd["mor"]))
	changed.emit()
	await _card_now(cd["key"])
	if research and has_card("rorg") and int(S["pv"][GER]) >= 2:
		var yes = await decide(GER, {"type": "yesno", "why": "rorg", "text": "Ricerca organizzata: perdere 2 PV per avanzare di una posizione sul tracciato Ricerca?"})
		if yes == true:
			gain_pv(GER, -2)
			gain_ric(1)
			log_msg("Ricerca organizzata: il tedesco perde 2 PV e avanza sul tracciato Ricerca.")
	changed.emit()


## Effetti immediati (fulmine) delle carte.
func _card_now(key: String) -> void:
	match key:
		"gen":
			await _swap_generals()
		"prop":
			for a in card_allies():
				if not S["start"][a].is_empty():
					var r = await decide(a, {"type": "discard_start", "why": "Contro propaganda: scarta una pedina dalla tua area di partenza.", "options": S["start"][a].duplicate()})
					await _force_discard(a, r)
		"uboot":
			await _make_fortresses(1, D.UBOOT_TERR)
		"gustav":
			await _make_fortresses(2, [])
		"difesa":
			var n := controlled(GER)
			gain_pv(GER, 2 * n)
			log_msg("Difesa avanzata: %d PV per %d Territori controllati." % [2 * n, n])
		"atomica":
			for a in card_allies():
				gain_mor(a, -1)
				gain_pol(a, -1)
			log_msg("Bomba atomica: ogni Alleato perde 1 Morale e 1 Politica.")
		"visita":
			var m = await decide(GER, {"type": "visita"})
			var mm := clampi(int(m) if (m is int or m is float) else 3, 0, 3)
			gain_mor(GER, mm)
			gain_pol(GER, 3 - mm)
			var fan := 0
			for t in D.T_KEY.size():
				for sl in S["terr"][t]["sl"]:
					if sl != null and int(sl["f"]) == GER and int(sl["t"]) == D.FAN:
						fan += 1
			gain_pv(GER, 2 * fan)
			log_msg("Visita dei generali: +%d Morale, +%d Politica e %d PV per le Fanterie in campo." % [mm, 3 - mm, 2 * fan])


func _force_discard(a: int, r) -> void:
	var p := int(r) if (r is int or r is float) else -1
	if not (p in S["start"][a]):
		if S["start"][a].is_empty():
			return
		p = S["start"][a][0]
	S["start"][a].erase(p)
	S["loc"][p] = "disc"
	log_msg("%s scarta %s dalla sua area di partenza." % [pname(a), D.TYPE_NAME[D.P_FRONT[p]]])
	changed.emit()


## L'Alleato scelto scarta dalla sua area di partenza una pedina dei tipi indicati (se ne ha).
func _ally_discard_types(chooser_text: String, types: Array, all_allies: bool) -> void:
	var targets := []
	for a in card_allies():
		for p in S["start"][a]:
			if int(D.P_FRONT[p]) in types:
				targets.append(a)
				break
	if targets.is_empty():
		return
	var who := targets
	if not all_allies:
		var r = await decide(GER, {"type": "target", "why": chooser_text, "options": targets})
		var a := int(r) if (r is int or r is float) else -1
		who = [a if a in targets else targets[0]]
	for a in who:
		var cand := []
		for p in S["start"][a]:
			if int(D.P_FRONT[p]) in types:
				cand.append(p)
		if cand.is_empty():
			continue
		var pick = cand[0]
		if cand.size() > 1:
			pick = await decide(a, {"type": "discard_start", "why": chooser_text, "options": cand})
		await _force_discard(a, pick)


func _swap_generals() -> void:
	var disc := discards(GER)
	var res := reserve(GER)
	var n := mini(2, mini(disc.size(), res.size()))
	if n <= 0:
		return
	var r = await decide(GER, {"type": "swap", "n": n, "disc": disc, "res_types": reserve_types(GER)})
	var take: Array = []
	var give: Array = []
	if r is Dictionary:
		take = r.get("disc", [])
		give = r.get("res", [])
	var done := 0
	for k in n:
		var p := int(take[k]) if k < take.size() else -1
		if not (p in discards(GER)):
			p = discards(GER)[0]
		var t := int(give[k]) if k < give.size() else -1
		var q := _random_of_type(GER, t)
		if q < 0:
			continue
		S["loc"][p] = "res"
		S["loc"][q] = "disc"
		done += 1
	log_msg("Sostituzione dei generali: %d pedine tornano dagli scarti nella riserva tedesca." % done)
	changed.emit()


## Una pedina a caso della riserva di f del tipo indicato (la scelta è "alla cieca": il retro non si vede).
func _random_of_type(f: int, t: int) -> int:
	var c := []
	for p in reserve(f):
		if int(D.P_FRONT[p]) == t:
			c.append(p)
	if c.is_empty():
		c = reserve(f)
	if c.is_empty():
		return -1
	return c[rng.randi() % c.size()]


func _make_fortresses(n: int, allowed: Array) -> void:
	for k in n:
		var terr := []
		for t in D.T_KEY.size():
			var T: Dictionary = S["terr"][t]
			if t == D.BERLIN or T["al"] or T["fort"]:
				continue
			if not allowed.is_empty() and not (D.T_KEY[t] in allowed):
				continue
			terr.append(t)
		var disc := discards(GER)
		if terr.is_empty() or disc.is_empty():
			return
		var r = await decide(GER, {"type": "fortress", "terr": terr, "pawns": disc})
		var t := int(r.get("t", -1)) if r is Dictionary else -1
		var p := int(r.get("p", -1)) if r is Dictionary else -1
		if not (t in terr):
			t = terr[0]
		if not (p in disc):
			p = disc[0]
		var T: Dictionary = S["terr"][t]
		for i in 3:
			var sl = T["sl"][i]
			if sl != null:
				S["loc"][int(sl["p"])] = "disc"
				T["sl"][i] = null
		var tt := int(D.P_FRONT[p])
		T["cp"] = {"p": p, "f": GER, "t": tt, "s": strength_for(GER, tt)}
		S["loc"][p] = "ctrl"
		T["fort"] = true
		log_msg("Il tedesco trasforma %s in Fortezza." % D.T_NAME[t])
		_fx("fortress", {"t": t})
		await _first_conquest(GER, t)


# ------------------------------------------------------------------ uso delle pedine

## Applica l'uso di una pedina. f gioca; back = pedina ricevuta girata sul retro.
func apply_use(f: int, pid: int, back: bool, use: Dictionary) -> void:
	var t := ptype(pid, back)
	var holder := D.owner(pid)
	S["start"][holder].erase(pid)
	S["loc"][pid] = "disc"
	var a := str(use.get("a", "discard"))
	var desc := ""
	match a:
		"place":
			var tid := int(use["t"])
			var i := int(use["i"])
			var s := strength_for(f, t)
			var T: Dictionary = S["terr"][tid]
			var occ = T["sl"][i]
			if occ != null:
				S["loc"][int(occ["p"])] = "disc"
				desc = "%s: %s elimina %s %s" % [D.T_NAME[tid], D.TYPE_NAME[t], D.TYPE_NAME[int(occ["t"])], D.FAC_SHORT[int(occ["f"])]]
			else:
				desc = "%s: %s" % [D.T_NAME[tid], D.TYPE_NAME[t]]
			T["sl"][i] = {"p": pid, "f": f, "t": t, "s": s}
			S["loc"][pid] = "slot"
			log_msg("%s piazza %s." % [pname(f), desc])
			_fx("place", {"t": tid, "i": i, "f": f})
		"berlin":
			var i := int(use["i"])
			var box := {"p": pid, "f": f, "t": t}
			var pv := 1
			var b := ""
			if S["ber"][i] == null:
				S["ber"][i] = box
				pv = D.BER_PV[i]
				b = D.BER_BONUS[i]
			else:
				S["berx"].append(box)
			S["loc"][pid] = "ber"
			gain_pv(f, pv)
			if b == "pol":
				gain_pol(f, 1)
			elif b == "mor":
				gain_mor(f, 1)
			log_msg("%s entra a Berlino (%s): %d PV%s." % [pname(f), D.TYPE_NAME[t], pv, (" e " + ("Politica" if b == "pol" else "Morale")) if b != "" else ""])
			_fx("berlin", {"i": i, "f": f})
			if berlin_count() >= 6 and not S["ber_full"]:
				S["ber_full"] = true
				log_msg("Tutte e sei le caselle di Berlino sono occupate: la partita finisce alla fine di questo giro.")
		"share":
			var tid := int(use["t"])
			S["terr"][tid]["share"].append({"f": f, "p": pid})
			S["loc"][pid] = "share"
			log_msg("%s condivide %s con una pedina %s." % [pname(f), D.T_NAME[tid], D.TYPE_NAME[t]])
		"conf":
			var i := int(use["i"])
			S["conf"][i] = {"p": pid, "f": f}
			S["loc"][pid] = "conf"
			log_msg("%s %s la Conferenza." % [pname(f), "dichiara" if _conf_count() == 1 else "si unisce al"])
			_conf_bonus(f, i)
			if _conf_count() >= 3:
				S["conf_closed"] = true
				log_msg("La Conferenza è al completo e si chiude.")
		"mor":
			gain_mor(f, 2 if t == D.MOR2 else 1)
			log_msg("%s scarta %s e avanza sul tracciato Morale." % [pname(f), D.TYPE_NAME[t]])
		"pol":
			gain_pol(f, 1)
			log_msg("%s scarta %s e avanza sul tracciato Politica." % [pname(f), D.TYPE_NAME[t]])
		"ric":
			gain_ric(2 if t == D.RIC2 else 1)
			log_msg("Il tedesco scarta %s e avanza sul tracciato Ricerca." % D.TYPE_NAME[t])
		"ricback":
			gain_ric(-1)
			log_msg("%s scarta %s: la Ricerca tedesca arretra." % [pname(f), D.TYPE_NAME[t]])
		"eve":
			log_msg("%s scarta %s per il tracciato Eventi." % [pname(f), D.TYPE_NAME[t]])
			await event_advance(f)
		_:
			log_msg("%s scarta %s (nessun uso possibile)." % [pname(f), D.TYPE_NAME[t]])
	changed.emit()
	if a == "place":
		var T2: Dictionary = S["terr"][int(use["t"])]
		if T2["sl"][0] != null and T2["sl"][1] != null and T2["sl"][2] != null:
			await _resolve(int(use["t"]))
	# effetti delle carte tedesche
	if f == GER:
		await _ger_triggers(t)
	elif t == D.SIM and has_card("enigma") and not (two() and f == D.USA) and a != "discard":
		var yes = await decide(GER, {"type": "yesno", "why": "enigma", "text": "Enigma 2: un Alleato ha usato un Simbolo Fazione. Perdere 1 Morale per ottenere 4 PV?"})
		if yes == true:
			gain_mor(GER, -1)
			gain_pv(GER, 4)
			log_msg("Enigma 2: il tedesco perde 1 Morale e ottiene 4 PV.")
	elif t == D.POL and has_card("spie") and not (two() and f == D.USA) and a != "discard":
		await _spies()
	if f == GER:
		await maybe_buy()
	changed.emit()


func _conf_count() -> int:
	var n := 0
	for c in S["conf"]:
		if c != null:
			n += 1
	return n


func _conf_bonus(f: int, i: int) -> void:
	match D.CONF_BONUS[i]:
		"pol":
			gain_pol(f, 1)
		"mor":
			gain_mor(f, 1)
		"pv2":
			gain_pv(f, 2)


func _ger_triggers(t: int) -> void:
	if t == D.ART:
		if has_card("v1"):
			var a = await _pick_ally("Bomba V1: quale Alleato perde 1 Morale?")
			if a >= 0:
				gain_mor(a, -1)
				gain_mor(GER, 1)
				log_msg("Bomba V1: %s perde 1 Morale, il tedesco ne guadagna 1." % pname(a))
		if has_card("v2"):
			var a = await _pick_ally("Bomba V2: quale Alleato perde 1 Politica?")
			if a >= 0:
				gain_pol(a, -1)
				gain_pv(GER, 2)
				log_msg("Bomba V2: %s perde 1 Politica, il tedesco ottiene 2 PV." % pname(a))
		if has_card("v3"):
			var a = await _pick_ally("Bomba V3: quale Alleato perde 2 PV?")
			if a >= 0:
				gain_pv(a, -2)
				gain_pv(GER, 2)
				log_msg("Bomba V3: %s perde 2 PV, il tedesco ne ottiene 2." % pname(a))
	if t == D.ART or t == D.AVI:
		if has_card("ala"):
			await _ally_discard_types("Bombardieri a tutt'ala: quale Alleato scarta una Fanteria o un Corazzati dall'area di partenza?", [D.FAN, D.COR], false)
		if has_card("strat"):
			gain_pv(GER, 3)
			log_msg("Bombardieri strategici: il tedesco ottiene 3 PV.")


func _pick_ally(why: String) -> int:
	var r = await decide(GER, {"type": "target", "why": why, "options": card_allies()})
	var a := int(r) if (r is int or r is float) else -1
	return a if a in card_allies() else card_allies()[0]


## Rete di spie: il tedesco gira una pedina per ogni Alleato e decide come gliela fa giocare.
func _spies() -> void:
	S["spied"] = []
	for a in card_allies():
		for p in S["start"][a]:
			S["spied"].append(p)
	log_msg("Rete di spie: il tedesco guarda i retri delle pedine nelle aree di partenza alleate.")
	for a in card_allies():
		if S["start"][a].is_empty():
			continue
		var r = await decide(GER, {"type": "spy_pick", "ally": a, "options": S["start"][a].duplicate()})
		var p := int(r) if (r is int or r is float) else -1
		if not (p in S["start"][a]):
			p = S["start"][a][0]
		var tg := gift_targets(a, p)
		if tg.is_empty():
			tg = [GER]
		var to: int = tg[0]
		if tg.size() > 1:
			var rr = await decide(GER, {"type": "target", "why": "Rete di spie: a chi va la pedina girata?", "options": tg})
			to = _int(rr, tg[0])
			if not (to in tg):
				to = tg[0]
		var uses := legal_uses(to, p, true)
		var u = await decide(GER, {"type": "spy_use", "p": p, "to": to, "options": uses})
		if not (u is Dictionary) or not _use_in(u, uses):
			u = uses[0]
		log_msg("Rete di spie: la pedina di %s va a %s." % [pname(a), pname(to)])
		await apply_use(to, p, true, u)
	S["spied"] = []


func _use_in(u: Dictionary, uses: Array) -> bool:
	for x in uses:
		if str(x.get("a")) == str(u.get("a")) and int(x.get("t", -1)) == int(u.get("t", -1)) and int(x.get("i", -1)) == int(u.get("i", -1)):
			return true
	return false


# ------------------------------------------------------------------ territori

func _resolve(tid: int) -> void:
	var T: Dictionary = S["terr"][tid]
	var sl: Array = T["sl"]
	var cnt := {}
	for x in sl:
		cnt[int(x["f"])] = int(cnt.get(int(x["f"]), 0)) + 1
	var w := -1
	for f in cnt:
		if int(cnt[f]) >= 2:
			w = int(f)
	if w < 0:
		# tutte diverse: vince la pedina alleata più forte (in parità, chi è più avanti in Politica)
		for x in sl:
			var f := int(x["f"])
			if f == GER:
				continue
			if w < 0:
				w = f
				continue
			var bs := 0
			for y in sl:
				if int(y["f"]) == w:
					bs = int(y["s"])
			if int(x["s"]) > bs or (int(x["s"]) == bs and _pol_better(f, w)):
				w = f
	var mine := []
	for x in sl:
		if int(x["f"]) == w:
			mine.append(int(x["p"]))
	var keep := -1
	if w == GER:
		keep = await _ctrl_pick(w, tid, mine)
		T["cp"] = _slot_of(sl, keep)
		T["fort"] = true
		log_msg("%s: il tedesco ottiene la maggioranza e costruisce una Fortezza." % D.T_NAME[tid])
	else:
		if T["fort"]:
			var cps := int(T["cp"]["s"])
			var ok := []
			for x in sl:
				if int(x["f"]) == w and int(x["s"]) >= cps:
					ok.append(int(x["p"]))
			if ok.is_empty():
				for x in sl:
					S["loc"][int(x["p"])] = "disc"
				T["sl"] = [null, null, null]
				log_msg("%s: %s non riesce a sconfiggere la Fortezza tedesca, le pedine alleate vanno negli scarti." % [D.T_NAME[tid], pname(w)])
				_fx("fail", {"t": tid})
				changed.emit()
				return
			keep = await _ctrl_pick(w, tid, ok)
			S["loc"][int(T["cp"]["p"])] = "disc"
			log_msg("%s: %s espugna la Fortezza tedesca." % [D.T_NAME[tid], pname(w)])
		else:
			keep = await _ctrl_pick(w, tid, mine)
			log_msg("%s: %s conquista il Territorio." % [D.T_NAME[tid], pname(w)])
		T["cp"] = _slot_of(sl, keep)
		T["al"] = true
		T["fort"] = false
		T["ctrl"] = w
	S["loc"][keep] = "ctrl"
	for x in sl:
		if int(x["p"]) != keep:
			S["loc"][int(x["p"])] = "disc"
	T["sl"] = [null, null, null]
	_fx("conquest", {"t": tid, "f": w})
	changed.emit()
	await _first_conquest(w, tid)


func _slot_of(sl: Array, p: int) -> Dictionary:
	for x in sl:
		if int(x["p"]) == p:
			return (x as Dictionary).duplicate()
	return (sl[0] as Dictionary).duplicate()


func _ctrl_pick(f: int, tid: int, cand: Array) -> int:
	if cand.size() == 1:
		return cand[0]
	var r = await decide(f, {"type": "ctrl_pick", "t": tid, "options": cand})
	var p := int(r) if (r is int or r is float) else -1
	return p if p in cand else cand[0]


## Tessera Territorio (se c'è ancora) e PV del tracciato Morale.
func _first_conquest(f: int, tid: int) -> void:
	var T: Dictionary = S["terr"][tid]
	var tile := int(T["tile"])
	if tile >= 0:
		T["tile"] = -1
		S["tiles"][f].append(tile)
		gain_pv(f, int(D.TILE_PV[tile]))
		var parts := ["%d PV" % int(D.TILE_PV[tile])] if int(D.TILE_PV[tile]) > 0 else []
		for b in D.TILE_BONUS[tile]:
			match b:
				"ric":
					gain_ric(1 if f == GER else -1)
					parts.append("Ricerca")
				"pol":
					gain_pol(f, 1)
					parts.append("Politica")
				"mor":
					gain_mor(f, 1)
					parts.append("Morale")
				"eve":
					if f != GER:
						parts.append("Eventi")
				"card":
					parts.append("carta Ricerca")
		log_msg("%s prende la tessera di %s: %s." % [pname(f), D.T_NAME[tid], ", ".join(parts)])
		changed.emit()
		for b in D.TILE_BONUS[tile]:
			if b == "eve" and f != GER:
				await event_advance(f)
			elif b == "card":
				await _tile_card(f)
			elif b == "ric" and f == GER:
				await maybe_buy()
	var mp: int = D.MOR_PV[int(S["mor"][f])]
	if mp > 0:
		gain_pv(f, mp)
		log_msg("%s ottiene %d PV dal tracciato Morale." % [pname(f), mp])
	changed.emit()


func _tile_card(f: int) -> void:
	var l1: Array = S["cdisp"][0].duplicate()
	if l1.is_empty():
		return
	if f == GER:
		var r = await decide(GER, {"type": "free_card", "options": l1})
		var c: int = _int(r, l1[0])
		if not (c in l1):
			c = l1[0]
		await acquire(c, false)
	else:
		var r = await decide(f, {"type": "deny_card", "options": l1})
		var c: int = _int(r, l1[0])
		if not (c in l1):
			c = l1[0]
		_take_from_display(c)
		S["cgone"].append(c)
		log_msg("%s fa scartare al tedesco la carta Ricerca «%s»." % [pname(f), D.CARDS[c]["name"]])
		changed.emit()


# ------------------------------------------------------------------ Eventi

func event_advance(f: int) -> void:
	if f == GER:
		return
	var box := next_event_box(f)
	S["eve"][f] = box
	var ev: Dictionary = D.EVENTS[f][box - 1]
	var r = await decide(f, {"type": "event_opt", "box": box})
	var o := clampi(int(r) if (r is int or r is float) else 0, 0, 1)
	log_msg("%s: «%s»." % [pname(f), ev["name"]])
	_fx("event", {"f": f, "box": box, "o": o})
	for e in ev["opt"][o]:
		var who: int = _who(f, str(e[1]))
		if str(e[1]) == "any":
			var opts_t := []
			for g in 4:
				if g != f:
					opts_t.append(g)
			var rr = await decide(f, {"type": "target", "why": "%s: chi %s?" % [ev["name"], "perde 1 Morale" if int(e[2]) < 0 else "guadagna"], "options": opts_t, "eff": e})
			who = _int(rr, opts_t[0])
			if not (who in opts_t):
				who = opts_t[0]
		var n := int(e[2])
		match str(e[0]):
			"pv":
				gain_pv(who, n)
			"mor":
				gain_mor(who, n)
			"pol":
				gain_pol(who, n)
			"ric":
				gain_ric(n)
	changed.emit()


func _who(f: int, w: String) -> int:
	match w:
		"self":
			return f
		"ger":
			return GER
		"ussr":
			return D.USSR
		"usa":
			return D.USA
		"uk":
			return D.UK
	return f


func event_effect_text(f: int, e: Array) -> String:
	var n := int(e[2])
	var who := str(e[1])
	var target := ""
	match who:
		"self":
			target = ""
		"ger":
			target = " (tedesco)"
		"any":
			target = " (a scelta)"
		_:
			target = " (%s)" % D.FAC_SHORT[_who(f, who)]
	match str(e[0]):
		"pv":
			return "%+d PV%s" % [n, target]
		"mor":
			return "%+d Morale%s" % [n, target]
		"pol":
			return "%+d Politica%s" % [n, target]
		"ric":
			return "Ricerca tedesca %+d" % n
	return ""


# ------------------------------------------------------------------ partita

func run() -> void:
	log_msg("WunderWaffen: 1944, dallo sbarco in Normandia alla corsa verso Berlino.")
	if two():
		log_msg("Partita a due: Regno Unito e Unione Sovietica contro Stati Uniti e Germania.")
	if opts.get("hist", false):
		log_msg("Preparazione storica delle tessere Territorio.")
	changed.emit()
	# 6-8: ogni fazione sceglie le prime tre pedine
	for f in [D.USSR, D.USA, D.UK, GER]:
		await _pick(f, 3)
		if abort:
			return
	# 9: carte Ricerca iniziali del tedesco
	if not two() and not opts.get("nocards", false):
		var r = await decide(GER, {"type": "start_cards", "l1": S["cdisp"][0].duplicate(), "l2": S["cdisp"][1].duplicate()})
		var cs: Array = r if r is Array else []
		var ok := false
		if cs.size() == 1 and int(cs[0]) in S["cdisp"][1]:
			ok = true
		elif cs.size() == 2 and int(cs[0]) in S["cdisp"][0] and int(cs[1]) in S["cdisp"][0] and int(cs[0]) != int(cs[1]):
			ok = true
		if not ok:
			cs = [S["cdisp"][0][0], S["cdisp"][0][1]]
		for c in cs:
			await acquire(int(c), false)
	log_msg("Inizia %s." % pname(int(S["first"])))
	for part in [1, 2]:
		S["part"] = part
		if part == 2:
			await _setup_part2()
			if abort:
				return
		var max_rounds := 6 if part == 1 else 4
		S["round"] = 0
		while not abort:
			S["round"] = int(S["round"]) + 1
			log_msg("— Parte %d, giro %d —" % [part, int(S["round"])])
			_fx("round", {"part": part, "round": int(S["round"])})
			var i0: int = D.ORDER.find(int(S["first"]))
			for k in 4:
				var f: int = D.ORDER[(i0 + k) % 4]
				await _turn(f)
				if abort:
					return
			if S["ber_full"]:
				break
			if int(S["round"]) >= max_rounds or not _anyone_has_pawns():
				break
		if abort:
			return
		if part == 1 and not S["ber_full"]:
			_score_part1()
		else:
			break
	_final()


func _anyone_has_pawns() -> bool:
	for f in 4:
		if not S["start"][f].is_empty() or not reserve(f).is_empty():
			return true
	return false


## Scelta alla cieca di n pedine dalla riserva (si vede solo il fronte).
func _pick(f: int, n: int) -> void:
	var res := reserve(f)
	n = mini(n, res.size())
	if n <= 0:
		return
	var types := reserve_types(f)
	var r = await decide(f, {"type": "pick", "n": n, "types": types})
	var want: Array = r if r is Array else []
	var got := []
	for k in n:
		var t := int(want[k]) if k < want.size() else -1
		var p := _random_of_type(f, t)
		if p < 0:
			break
		S["loc"][p] = "start"
		S["start"][f].append(p)
		got.append(int(D.P_FRONT[p]))
	changed.emit()
	if f == GER:
		if has_card("jet") and D.AVI in got:
			await _ally_discard_types("Aerei a reazione: quale Alleato scarta una pedina Aviazione dall'area di partenza?", [D.AVI], false)
		if has_card("carri") and int(S["part"]) == 2 and D.COR in got:
			await _ally_discard_types("Carri armati pesanti: ogni Alleato scarta un Corazzati dall'area di partenza.", [D.COR], true)


func _turn(f: int) -> void:
	S["cur"] = f
	S["bought"] = false
	S["step"] = int(S["step"]) + 1
	changed.emit()
	_fx("turn", {"f": f})
	if S["start"][f].is_empty():
		if reserve(f).is_empty():
			log_msg("%s non ha più pedine e salta il turno." % pname(f))
			return
		await _pick(f, 3)
		return
	# bonus della Conferenza per chi c'è dentro
	if f != GER and not S["conf_closed"]:
		var inside := false
		for c in S["conf"]:
			if c != null and int(c["f"]) == f:
				inside = true
		if inside:
			var free := []
			for i in 3:
				if S["conf"][i] == null:
					free.append(i)
			if not free.is_empty():
				var r = await decide(f, {"type": "conf_bonus", "options": free})
				var i: int = _int(r, free[0])
				if not (i in free):
					i = free[0]
				_conf_bonus(f, i)
				log_msg("%s riceve il bonus della Conferenza." % pname(f))
				changed.emit()
	if f == GER:
		await maybe_buy()
	var n: int = S["start"][f].size()
	var self_left := 2 if n >= 3 else 1
	var gift_left := 1 if n >= 2 else 0
	var guard := 0
	while (self_left > 0 or gift_left > 0) and not S["start"][f].is_empty() and not abort:
		guard += 1
		if guard > 12:
			break
		var can_gift := false
		for p in S["start"][f]:
			if not gift_targets(f, p).is_empty():
				can_gift = true
		var req := {"type": "turn", "pawns": S["start"][f].duplicate(), "self_left": self_left,
			"gift_left": gift_left, "can_gift": can_gift}
		if f == GER and has_card("rfin"):
			var l1 := []
			for c in S["cards"]:
				if int(D.CARDS[c]["lvl"]) == 1:
					l1.append(c)
			if not l1.is_empty() and int(S["ric"]) < D.RIC_MAX:
				req["rfin"] = l1
		var r = await decide(f, req)
		var m: Dictionary = _valid_move(f, r, req)
		match str(m["k"]):
			"self":
				self_left -= 1
				await apply_use(f, int(m["p"]), false, m["use"])
			"gift":
				gift_left -= 1
				var p := int(m["p"])
				var to := int(m["to"])
				S["start"][f].erase(p)
				S["loc"][p] = "gift"
				log_msg("%s dà una pedina a %s." % [pname(f), pname(to)])
				_fx("gift", {"from": f, "to": to, "p": p})
				changed.emit()
				var uses := legal_uses(to, p, true)
				var u = await decide(to, {"type": "use_gift", "p": p, "from": f, "options": uses})
				if not (u is Dictionary) or not _use_in(u, uses):
					u = uses[0]
				await apply_use(to, p, true, u)
			"gdisc":
				gift_left -= 1
				var p := int(m["p"])
				S["start"][f].erase(p)
				S["loc"][p] = "disc"
				log_msg("%s non può dare pedine all'avversario e ne scarta una." % pname(f))
			"rfin":
				var c := int(m["c"])
				S["cards"].erase(c)
				S["cgone"].append(c)
				gain_ric(1)
				log_msg("Ricerca finalizzata: il tedesco scarta «%s» e avanza sul tracciato Ricerca." % D.CARDS[c]["name"])
				await maybe_buy()
		changed.emit()
		if S["over"]:
			return
	# eventuali pedine rimaste (non dovrebbe succedere) tornano negli scarti
	for p in S["start"][f].duplicate():
		S["start"][f].erase(p)
		S["loc"][p] = "disc"
	if f == GER:
		await maybe_buy()
	await _pick(f, 3)
	if f == GER and has_card("econ") and int(S["mor"][GER]) > 0:
		var yes = await decide(GER, {"type": "yesno", "why": "econ", "text": "Economia di guerra: perdere 1 Morale per ottenere 5 PV?"})
		if yes == true:
			gain_mor(GER, -1)
			gain_pv(GER, 5)
			log_msg("Economia di guerra: il tedesco perde 1 Morale e ottiene 5 PV.")
	changed.emit()


## Controlla la mossa ricevuta; se non è valida ne sceglie una valida (protegge da dati corrotti).
func _valid_move(f: int, r, req: Dictionary) -> Dictionary:
	if r is Dictionary:
		var k := str(r.get("k", ""))
		var p := int(r.get("p", -1))
		if k == "self" and p in S["start"][f] and int(req["self_left"]) > 0:
			var uses := legal_uses(f, p, false)
			if r.get("use") is Dictionary and _use_in(r["use"], uses):
				return {"k": "self", "p": p, "use": r["use"]}
		if k == "gift" and p in S["start"][f] and int(req["gift_left"]) > 0:
			var tg := gift_targets(f, p)
			if int(r.get("to", -1)) in tg:
				return {"k": "gift", "p": p, "to": int(r["to"])}
		if k == "gdisc" and p in S["start"][f] and int(req["gift_left"]) > 0 and not req["can_gift"]:
			return {"k": "gdisc", "p": p}
		if k == "rfin" and req.has("rfin") and int(r.get("c", -1)) in req["rfin"]:
			return {"k": "rfin", "c": int(r["c"])}
	# riserva: la prima mossa valida
	var p0: int = S["start"][f][0]
	if int(req["self_left"]) > 0:
		return {"k": "self", "p": p0, "use": legal_uses(f, p0, false)[0]}
	for p in S["start"][f]:
		var tg := gift_targets(f, p)
		if not tg.is_empty():
			return {"k": "gift", "p": p, "to": tg[0]}
	return {"k": "gdisc", "p": p0}


func _setup_part2() -> void:
	log_msg("— Seconda parte: gli eserciti si riorganizzano —")
	_fx("part2", {})
	for i in 3:
		var c = S["conf"][i]
		if c != null:
			S["loc"][int(c["p"])] = "disc"
			S["conf"][i] = null
	S["conf_closed"] = false
	for f in 4:
		for p in S["start"][f]:
			S["loc"][p] = "disc"
		S["start"][f] = []
		for k in 18:
			var p := f * 18 + k
			if S["loc"][p] == "disc" or S["loc"][p] == "res":
				S["loc"][p] = "res"
	changed.emit()
	for f in [D.USSR, D.USA, D.UK, GER]:
		var res := reserve(f)
		if res.size() > 12:
			var r = await decide(f, {"type": "pick", "n": 12, "types": reserve_types(f), "keep": true})
			var want: Array = r if r is Array else []
			var keep := []
			for k in 12:
				var t := int(want[k]) if k < want.size() else -1
				var p := _random_of_type(f, t)
				if p < 0:
					break
				S["loc"][p] = "keep"
				keep.append(p)
			for p in reserve(f):
				S["loc"][p] = "gone"
			for p in keep:
				S["loc"][p] = "res"
			log_msg("%s tiene 12 pedine per la seconda parte." % pname(f))
		changed.emit()
	for f in [D.USSR, D.USA, D.UK, GER]:
		await _pick(f, 3)


func _score_part1() -> void:
	log_msg("— Fine della prima parte —")
	var parts := []
	for f in 4:
		var n := 0
		if f == GER:
			n = controlled(GER)
		else:
			n = S["tiles"][f].size()
		gain_pv(f, n)
		parts.append("%s +%d" % [D.FAC_NAME[f], n])
	log_msg("Punti della prima parte: " + ", ".join(parts) + ".")
	_fx("part1", {})
	changed.emit()


func final_breakdown() -> Dictionary:
	var out := {}
	var lead := politics_leader()
	# Berlino: chi ha più pedine
	var cnt := [0, 0, 0, 0]
	var val := [0, 0, 0, 0]
	for b in S["ber"] + S["berx"]:
		if b == null:
			continue
		var f := int(b["f"])
		cnt[f] += 1
		match int(b["t"]):
			D.POL:
				val[f] += 3
			D.SIM:
				val[f] += 2
			_:
				val[f] += 1
	var top := 0
	for f in 4:
		top = maxi(top, cnt[f])
	var rockets := 0
	for c in S["cards"]:
		if int(D.CARDS[c]["rocket"]) > 0:
			rockets += 1
	var atomc := 0
	for c in S["cards"]:
		if int(D.CARDS[c]["atom"]) > 0:
			atomc += 1
	for f in 4:
		var b := {"base": int(S["pv"][f]), "terr": controlled(f), "pol": 10 if f == lead else 0,
			"berlin": val[f] if (top > 0 and cnt[f] == top) else 0, "cards": 0}
		if f == GER:
			if has_card("uranio"):
				b["cards"] += 2 * atomc
			if has_card("braun"):
				b["cards"] += 2 * rockets
			if has_card("v3"):
				b["cards"] += rockets
		b["total"] = int(b["base"]) + int(b["terr"]) + int(b["pol"]) + int(b["berlin"]) + int(b["cards"])
		out[f] = b
	return out


func _final() -> void:
	S["over"] = true
	var br := final_breakdown()
	for f in 4:
		S["pv"][f] = int(br[f]["total"])
	var winners := []
	if two():
		var a := mini(int(br[D.UK]["total"]), int(br[D.USSR]["total"]))
		var b := mini(int(br[D.USA]["total"]), int(br[GER]["total"]))
		results = {"breakdown": br, "teams": [a, b]}
		if a > b:
			winners = [D.UK, D.USSR]
		elif b > a:
			winners = [D.USA, GER]
		else:
			winners = [D.UK, D.USSR, D.USA, GER]
	else:
		var best := -1
		for f in 4:
			best = maxi(best, int(br[f]["total"]))
		for f in 4:
			if int(br[f]["total"]) == best:
				winners.append(f)
		results = {"breakdown": br}
	results["winners"] = winners
	var names := []
	for w in winners:
		names.append(D.FAC_NAME[w])
	log_msg("Fine della partita. Vince: %s." % " e ".join(names))
	changed.emit()
	game_ended.emit(results)


## Impronta della partita (per confrontare le partite online fra dispositivi).
func fingerprint() -> String:
	var parts := [str(S["part"]), str(S["round"]), str(S["pv"]), str(S["mor"]), str(S["pol"]), str(S["eve"]), str(S["ric"]), str(S["cards"])]
	for t in D.T_KEY.size():
		var T: Dictionary = S["terr"][t]
		parts.append("%d%d%d" % [int(T["al"]), int(T["fort"]), int(T["ctrl"])])
	return "|".join(parts)
