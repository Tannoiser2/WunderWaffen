class_name WWAI
extends RefCounted
## Giocatore artificiale di WunderWaffen.
## Ogni mossa del turno (usare una pedina per sé, darne una girata a un altro) viene provata su una
## copia della partita e valutata con una stima del punteggio finale: punti già fatti, territori,
## Morale e Politica, Ricerca e carte del tedesco, presenza sul tabellone e su Berlino.
## L'IA vuole vincere: conta il proprio punteggio meno quello dell'avversario più pericoloso.
## Livelli: 0 Facile (scelte approssimative), 1 Normale, 2 Difficile (prova più mosse e le risposte).

const D = preload("res://scripts/data/ww_data.gd")
const GER := 0

var level := 1
var rng := RandomNumberGenerator.new()

const CARD_VALUE := {"v1": 4.0, "jet": 3.0, "rfin": 2.0, "acqua": 2.5, "gen": 2.0, "ala": 3.5, "mecc": 3.0, "sci": 3.5,
	"prop": 4.0, "rorg": 2.0, "carri": 2.5, "uboot": 5.5, "v2": 4.5, "spie": 3.0, "uranio": 5.0, "braun": 4.0,
	"difesa": 0.0, "strat": 6.0, "atomica": 6.0, "v3": 6.0, "enigma": 4.0, "econ": 6.0, "gustav": 7.5, "visita": 5.0}


# ------------------------------------------------------------------ valutazione

func _rounds_left(S: Dictionary) -> float:
	if int(S["part"]) == 1:
		return float(6 - int(S["round"])) + 4.0
	return float(maxi(0, 4 - int(S["round"])))


## Stima del punteggio finale della fazione f.
func est(e: WWEngine, f: int) -> float:
	var S := e.S
	var part1 := int(S["part"]) == 1
	var left := _rounds_left(S)
	var v := float(S["pv"][f])
	var terr := e.controlled(f)
	if f == GER:
		v += terr * (1.6 if part1 else 0.9)
		v += float(S["ric"]) * 1.3 + float(D.RIC_POINTS[int(S["ric"])]) * 0.8
		var rockets := 0
		var atomc := 0
		for c in S["cards"]:
			var cd: Dictionary = D.CARDS[c]
			if not cd["once"]:
				v += float(CARD_VALUE.get(cd["key"], 2.0)) * clampf(left / 8.0, 0.2, 1.0)
			if int(cd["rocket"]) > 0:
				rockets += 1
			if int(cd["atom"]) > 0:
				atomc += 1
		if e.has_card("uranio"):
			v += 2 * atomc
		if e.has_card("braun"):
			v += 2 * rockets
		if e.has_card("v3"):
			v += rockets
		v += float(S["mor"][GER]) * (1.0 if part1 else 0.5)
		for t in D.T_KEY.size():
			var T: Dictionary = S["terr"][t]
			if T["fort"] and T["cp"] != null:
				v += float(T["cp"]["s"]) * 0.35
	else:
		v += terr
		if part1:
			v += S["tiles"][f].size()
		v += float(S["mor"][f]) * (1.4 if part1 else 0.7)
		v += float(S["eve"][f]) * 0.35
	# Politica: 10 PV a chi è in testa alla fine
	var rank := [0, 1, 2, 3]
	rank.sort_custom(func(a, b): return e._pol_better(a, b))
	var pos := rank.find(f)
	if pos == 0:
		var margin := float(S["pol"][f]) - float(S["pol"][rank[1]])
		v += clampf(5.5 + margin * 1.8, 4.0, 9.5)
	elif pos == 1:
		v += 2.2
	else:
		v += 0.6
	# Berlino
	var cnt := [0, 0, 0, 0]
	var val := [0, 0, 0, 0]
	for b in S["ber"] + S["berx"]:
		if b == null:
			continue
		cnt[int(b["f"])] += 1
		val[int(b["f"])] += 3 if int(b["t"]) == D.POL else (2 if int(b["t"]) == D.SIM else 1)
	if cnt[f] > 0:
		var top := 0
		for g in 4:
			if g != f:
				top = maxi(top, cnt[g])
		v += float(val[f]) * (1.0 if cnt[f] >= top else 0.3)
	# presenza nei territori ancora aperti: probabilità di completare la conquista
	for t in D.T_KEY.size():
		var T: Dictionary = S["terr"][t]
		if T["al"] or t == D.BERLIN:
			continue
		var mine := 0
		var others := 0
		var ger := 0
		var mys := 0
		for sl in T["sl"]:
			if sl == null:
				continue
			if int(sl["f"]) == f:
				mine += 1
				mys += int(sl["s"])
			elif int(sl["f"]) == GER:
				ger += 1
			else:
				others += 1
		if mine == 0:
			continue
		var tv := _terr_value(e, t, f)
		if f == GER:
			v += tv * (0.45 if mine >= 2 else 0.15) * (1.0 if others == 0 else 0.6)
		else:
			var p := 0.22 if mine == 1 else 0.55
			if ger > 0:
				p *= 0.55
			if others > 0:
				p *= 0.8
			# pedine deboli si fanno eliminare facilmente
			var avg := float(mys) / float(mine)
			p *= clampf(0.45 + avg * 0.15, 0.5, 1.15)
			if T["fort"] and T["cp"] != null and avg < float(T["cp"]["s"]):
				p *= 0.6
			v += tv * p
	# pedine ancora da giocare
	v += 0.45 * float(S["start"][f].size() + e.reserve(f).size())
	return v


func utility(e: WWEngine, f: int) -> float:
	if e.two():
		var mine := []
		var opp := []
		for g in 4:
			if e.team_of(g) == e.team_of(f):
				mine.append(est(e, g))
			else:
				opp.append(est(e, g))
		return minf(mine[0], mine[1]) - minf(opp[0], opp[1]) + 0.15 * est(e, f)
	var me := est(e, f)
	var best := -1e9
	var sum := 0.0
	for g in 4:
		if g == f:
			continue
		var x := est(e, g)
		sum += x
		best = maxf(best, x)
	return me - 0.7 * best - 0.1 * sum


## Quanto vale conquistare il territorio t per f (tessera, PV del Morale, punto territorio).
func _terr_value(e: WWEngine, t: int, f: int) -> float:
	var T: Dictionary = e.S["terr"][t]
	var v := 1.0 + float(D.MOR_PV[int(e.S["mor"][f])])
	var tile := int(T["tile"])
	if tile >= 0:
		v += float(D.TILE_PV[tile]) + 1.3 * float(D.TILE_BONUS[tile].size())
	if f == GER:
		v += 1.0
	# vicino a Berlino vale di più per gli Alleati
	if f != GER and D.BERLIN in D.T_ADJ[t]:
		v += 1.0
	return v


# ------------------------------------------------------------------ politica rapida (usata anche nelle simulazioni)

func policy(e: WWEngine, f: int, req: Dictionary):
	return _quick(e, f, req)


func _quick(e: WWEngine, f: int, req: Dictionary):
	match str(req.get("type", "")):
		"turn":
			return _quick_turn(e, f, req)
		"use_gift", "spy_use":
			var who := f if req["type"] == "use_gift" else int(req["to"])
			var best = null
			var bs := -1e9
			for u in req["options"]:
				var sc := use_score(e, who, int(req["p"]), true, u)
				if req["type"] == "spy_use":
					sc = -sc
				if sc > bs:
					bs = sc
					best = u
			return best
		"pick":
			return _pick_types(e, f, req)
		"start_cards":
			return _start_cards(e, req)
		"ctrl_pick":
			return _ctrl_pick(e, f, req)
		"event_opt":
			return _event_opt(e, f, req)
		"target":
			return _target(e, f, req)
		"buy":
			return _buy(e, req)
		"conf_bonus":
			var bestb: int = req["options"][0]
			var bv := -1e9
			for i in req["options"]:
				var vv: float = {"pol": 2.2 + (1.0 if e.politics_leader() != f else 0.0), "pv2": 2.0, "mor": 1.6 if int(e.S["part"]) == 1 else 1.0}.get(D.CONF_BONUS[i], 1.0)
				if vv > bv:
					bv = vv
					bestb = i
			return bestb
		"discard_start":
			var worst: int = req["options"][0]
			var wv := 1e9
			for p in req["options"]:
				var vv := _pawn_worth(e, f, p)
				if vv < wv:
					wv = vv
					worst = p
			return worst
		"deny_card", "free_card":
			var bc: int = req["options"][0]
			var bvv := -1e9
			for c in req["options"]:
				var vv := card_worth(e, c)
				if vv > bvv:
					bvv = vv
					bc = c
			return bc
		"yesno":
			return _yesno(e, req)
		"swap":
			var disc: Array = req["disc"].duplicate()
			disc.sort_custom(func(a, b): return _pawn_worth(e, GER, a) > _pawn_worth(e, GER, b))
			var types: Dictionary = req["res_types"]
			var tl: Array = types.keys()
			tl.sort_custom(func(a, b): return _type_worth(e, GER, int(a)) < _type_worth(e, GER, int(b)))
			var give := []
			for t in tl:
				for k in int(types[t]):
					give.append(int(t))
			return {"disc": disc.slice(0, int(req["n"])), "res": give.slice(0, int(req["n"]))}
		"fortress":
			var bt: int = req["terr"][0]
			var btv := -1e9
			for t in req["terr"]:
				var vv := _terr_value(e, t, GER)
				for sl in e.S["terr"][t]["sl"]:
					if sl != null and int(sl["f"]) != GER:
						vv += 1.5
				if vv > btv:
					btv = vv
					bt = t
			var bp: int = req["pawns"][0]
			for p in req["pawns"]:
				if D.STRENGTH[int(D.P_FRONT[p])] > D.STRENGTH[int(D.P_FRONT[bp])]:
					bp = p
			return {"t": bt, "p": bp}
		"visita":
			var mm := 3 if e.S["mor"][GER] < 3 else 1
			if e.politics_leader() != GER and int(e.S["pol"][GER]) >= 2:
				mm = 1
			return mm
		"spy_pick":
			# la pedina il cui retro conviene di più al tedesco
			var bp2: int = req["options"][0]
			var bv2 := -1e9
			for p in req["options"]:
				var to := e.gift_targets(int(req["ally"]), p)
				var vv := 0.0
				if to.has(GER):
					vv += 3.0
				vv -= _pawn_worth(e, int(req["ally"]), p) * 0.3
				if vv > bv2:
					bv2 = vv
					bp2 = p
			return bp2
	return null


## Valore rapido di un uso di pedina per f (senza copiare la partita).
func use_score(e: WWEngine, f: int, pid: int, back: bool, u: Dictionary) -> float:
	var S := e.S
	var t := e.ptype(pid, back)
	var part1 := int(S["part"]) == 1
	match str(u.get("a")):
		"place":
			var tid := int(u["t"])
			var i := int(u["i"])
			var T: Dictionary = S["terr"][tid]
			var s := e.strength_for(f, t)
			var occ = T["sl"][i]
			var filled := 1
			var mine := 1
			var gerc := 1 if f == GER else 0
			for k in 3:
				if k == i:
					continue
				var x = T["sl"][k]
				if x != null:
					filled += 1
					if int(x["f"]) == f:
						mine += 1
					if int(x["f"]) == GER:
						gerc += 1
			var tv := _terr_value(e, tid, f)
			var sc := 0.0
			if occ != null:
				sc += 1.6 + 0.3 * float(occ["s"])
			if filled == 3:
				var w := _winner_after(e, tid, i, f, s, t)
				if w == f:
					sc += tv
					if T["fort"] and T["cp"] != null:
						var best := 0
						for k in 3:
							var x = T["sl"][k] if k != i else {"f": f, "s": s}
							if x != null and int(x["f"]) == f:
								best = maxi(best, int(x["s"]))
						if best < int(T["cp"]["s"]):
							sc -= tv + 1.0
				elif w == GER:
					sc -= 0.6 * tv
				else:
					sc -= 0.35 * tv
			else:
				if f == GER:
					# blocca i territori raggiungibili dagli Alleati
					var threat := 0.0
					for a in [D.USSR, D.USA, D.UK]:
						if e.access(a, tid):
							threat += 1.0
					sc += 0.5 + 0.45 * threat * float(filled) + 0.15 * tv
				else:
					sc += tv * 0.25 * float(mine) - (0.8 if gerc > 0 and filled == 2 else 0.0)
			# non sprecare pedine forti su caselle facili
			sc -= 0.12 * float(s - int(D.T_SLOTS[tid][i]))
			return sc
		"berlin":
			var i := int(u["i"])
			var pv := float(D.BER_PV[i]) if S["ber"][i] == null else 1.0
			return pv + (1.5 if D.BER_BONUS[i] != "" and S["ber"][i] == null else 0.0) + (3.0 if t == D.POL else (2.0 if t == D.SIM else 1.0)) * 0.7
		"share":
			return 1.4
		"conf":
			return 2.6
		"mor":
			return (1.6 if part1 else 0.9) * (2.0 if t == D.MOR2 else 1.0) - (1.0 if t == D.SIM else 0.0)
		"pol":
			var lead := e.politics_leader()
			return (2.4 if lead != f else 1.4) - (1.0 if t == D.SIM else 0.0)
		"ric":
			var step := 2 if t == D.RIC2 else 1
			var after := mini(int(S["ric"]) + step, D.RIC_MAX)
			return 1.3 * step + (1.5 if D.RIC_POINTS[after] > D.RIC_POINTS[int(S["ric"])] else 0.0) - (1.0 if t == D.SIM else 0.0)
		"ricback":
			return (1.6 if int(S["ric"]) >= 2 else 0.7) - (1.2 if t == D.SIM else 0.0)
		"eve":
			var box := e.next_event_box(f)
			var ev: Dictionary = D.EVENTS[f][box - 1]
			var b := maxf(_eff_value(e, f, ev["opt"][0]), _eff_value(e, f, ev["opt"][1]))
			return b + 0.3 - (1.0 if t == D.SIM else 0.0)
	return 0.0


func _winner_after(e: WWEngine, tid: int, i: int, f: int, s: int, t: int) -> int:
	var sl := []
	for k in 3:
		sl.append(e.S["terr"][tid]["sl"][k] if k != i else {"f": f, "s": s, "t": t})
	var cnt := {}
	for x in sl:
		cnt[int(x["f"])] = int(cnt.get(int(x["f"]), 0)) + 1
	for g in cnt:
		if int(cnt[g]) >= 2:
			return int(g)
	var w := -1
	var ws := -1
	for x in sl:
		if int(x["f"]) == GER:
			continue
		if int(x["s"]) > ws or (int(x["s"]) == ws and e._pol_better(int(x["f"]), w)):
			w = int(x["f"])
			ws = int(x["s"])
	return w


func _eff_value(e: WWEngine, f: int, effs: Array) -> float:
	var v := 0.0
	var part1 := int(e.S["part"]) == 1
	for x in effs:
		var k := str(x[0])
		var who := str(x[1])
		var n := float(x[2])
		var tgt := e._who(f, who)
		var sign := 1.0 if tgt == f else -0.6
		if tgt == GER:
			sign = -0.9
		if who == "any":
			# a scelta: si colpisce l'avversario più forte
			v += absf(n) * 1.2
			continue
		match k:
			"pv":
				v += n * sign
			"mor":
				v += n * sign * (1.5 if part1 else 0.8)
			"pol":
				v += n * sign * 2.0
			"ric":
				v += -n * 1.3
	return v


func _quick_turn(e: WWEngine, f: int, req: Dictionary) -> Dictionary:
	var best := {}
	var bs := -1e9
	for p in req["pawns"]:
		if int(req["self_left"]) > 0:
			for u in e.legal_uses(f, p, false):
				var sc := use_score(e, f, p, false, u)
				if sc > bs:
					bs = sc
					best = {"k": "self", "p": p, "use": u}
	if int(req["gift_left"]) > 0:
		for p in req["pawns"]:
			for to in e.gift_targets(f, p):
				var sc := -_gift_cost(e, f, p, to)
				# il regalo si fa per ultimo, salvo che sia l'unica cosa rimasta
				if int(req["self_left"]) > 0:
					sc -= 3.0
				if sc > bs:
					bs = sc
					best = {"k": "gift", "p": p, "to": to}
		if not req["can_gift"]:
			var worst: int = req["pawns"][0]
			for p in req["pawns"]:
				if _pawn_worth(e, f, p) < _pawn_worth(e, f, worst):
					worst = p
			if best.is_empty() or int(req["self_left"]) == 0:
				return {"k": "gdisc", "p": worst}
	if best.is_empty():
		var p0: int = req["pawns"][0]
		return {"k": "self", "p": p0, "use": e.legal_uses(f, p0, false)[0]}
	return best


## Quanto costa a f dare il retro di p a "to" (quanto aiuta un avversario).
func _gift_cost(e: WWEngine, f: int, p: int, to: int) -> float:
	var bt := int(D.P_BACK[p])
	var best := 0.0
	for u in e.legal_uses(to, p, true):
		best = maxf(best, use_score(e, to, p, true, u))
	var c := best
	if e.two() and e.team_of(to) == e.team_of(f):
		c = -c
	elif to != GER and f != GER:
		c *= 0.8     # un altro Alleato: rivale, ma contro il tedesco
	if bt == D.SIM:
		c += 0.5
	return c + _pawn_worth(e, f, p) * 0.4


func _pawn_worth(e: WWEngine, f: int, p: int) -> float:
	return _type_worth(e, f, int(D.P_FRONT[p]))


func _type_worth(e: WWEngine, f: int, t: int) -> float:
	match t:
		D.SIM:
			return 5.0
		D.ART:
			return 4.0
		D.AVI:
			return 3.2
		D.COR:
			return 2.5
		D.FAN:
			return 1.5
		D.POL:
			return 2.8
		D.MOR:
			return 2.0
		D.MOR2:
			return 3.0
		D.RIC:
			return 2.6
		D.RIC2:
			return 4.0
	return 1.0


func _pick_types(e: WWEngine, f: int, req: Dictionary) -> Array:
	var types: Dictionary = req["types"].duplicate()
	var n := int(req["n"])
	var out := []
	var keep: bool = req.get("keep", false)
	# un esemplare per tipo, per valutare cosa si potrebbe fare con quella pedina adesso
	var sample := {}
	for p in e.reserve(f):
		var t := int(D.P_FRONT[p])
		if not sample.has(t):
			sample[t] = p
	var score := {}
	for t in types:
		var base := _type_worth(e, f, int(t))
		if not keep and sample.has(t):
			var bu := 0.0
			for u in e.legal_uses(f, sample[t], false):
				bu = maxf(bu, use_score(e, f, sample[t], false, u))
			base = base * 0.4 + bu
		if f == GER and int(t) in [D.RIC, D.RIC2] and int(e.S["part"]) == 1:
			base += 1.0
		if f != GER and int(t) == D.POL and e.allied_around_berlin() >= 3:
			base += 1.5
		score[t] = base + (rng.randf() * (2.0 if level == 0 else 0.4))
	for k in n:
		var bt := -1
		var bv := -1e9
		for t in types:
			if int(types[t]) <= 0:
				continue
			# varietà: ogni copia dello stesso tipo vale un po' meno
			var v: float = score[t] - 0.6 * float(out.count(int(t)))
			if v > bv:
				bv = v
				bt = int(t)
		if bt < 0:
			break
		out.append(bt)
		types[bt] = int(types[bt]) - 1
	return out


func card_worth(e: WWEngine, c: int) -> float:
	var cd: Dictionary = D.CARDS[c]
	var v := float(cd["pv"]) + 2.0 * float(cd["pol"]) + 1.5 * float(cd["mor"])
	var k: String = cd["key"]
	if k == "difesa":
		v += 2.0 * e.controlled(GER)
	elif k == "visita":
		v += 6.0
	else:
		v += float(CARD_VALUE.get(k, 2.0)) * clampf(_rounds_left(e.S) / 8.0, 0.3, 1.0)
	if int(cd["atom"]) > 0 and e.has_card("uranio"):
		v += 2.0
	if int(cd["rocket"]) > 0 and e.has_card("braun"):
		v += 2.0
	return v


func _start_cards(e: WWEngine, req: Dictionary) -> Array:
	var l1: Array = req["l1"].duplicate()
	l1.sort_custom(func(a, b): return card_worth(e, a) > card_worth(e, b))
	var best2 := card_worth(e, l1[0]) + card_worth(e, l1[1])
	var bl2: int = req["l2"][0]
	for c in req["l2"]:
		if card_worth(e, c) > card_worth(e, bl2):
			bl2 = c
	if card_worth(e, bl2) > best2:
		return [bl2]
	return [l1[0], l1[1]]


func _buy(e: WWEngine, req: Dictionary) -> int:
	var best := -1
	var bv := -1e9
	for c in req["options"]:
		var v := card_worth(e, c) + 0.8 * float(D.CARDS[c]["lvl"])
		if v > bv:
			bv = v
			best = c
	# con pochi punti si aspetta una carta migliore, se c'è tempo
	var pts: int = D.RIC_POINTS[int(e.S["ric"])]
	if pts < 3 and int(e.S["ric"]) < D.RIC_MAX and _rounds_left(e.S) > 4 and level > 0:
		var lvl_best := 0
		for c in req["options"]:
			lvl_best = maxi(lvl_best, int(D.CARDS[c]["lvl"]))
		if lvl_best < pts and bv < 6.0:
			return -1
	return best


func _ctrl_pick(e: WWEngine, f: int, req: Dictionary) -> int:
	var best: int = req["options"][0]
	for p in req["options"]:
		var a := _ctrl_strength(e, int(req["t"]), p)
		var b := _ctrl_strength(e, int(req["t"]), best)
		if f == GER:
			if a > b:
				best = p
		else:
			# si lascia sul controllo la pedina meno utile per la seconda parte
			if _pawn_worth(e, f, p) < _pawn_worth(e, f, best):
				best = p
	return best


func _ctrl_strength(e: WWEngine, t: int, p: int) -> int:
	for sl in e.S["terr"][t]["sl"]:
		if sl != null and int(sl["p"]) == p:
			return int(sl["s"])
	return 0


func _event_opt(e: WWEngine, f: int, req: Dictionary) -> int:
	var ev: Dictionary = D.EVENTS[f][int(req["box"]) - 1]
	var a := _eff_value(e, f, ev["opt"][0])
	var b := _eff_value(e, f, ev["opt"][1])
	if level == 0:
		a += rng.randf() * 2.0
		b += rng.randf() * 2.0
	return 0 if a >= b else 1


func _target(e: WWEngine, f: int, req: Dictionary) -> int:
	var opts: Array = req["options"]
	var eff = req.get("eff", null)
	var positive := eff is Array and int(eff[2]) > 0
	var best: int = opts[0]
	var bv := -1e9 if not positive else 1e9
	for g in opts:
		var v := est(e, g)
		if e.two() and e.team_of(g) == e.team_of(f):
			v = -100.0 + v
		if positive:
			if v < bv:
				bv = v
				best = g
		else:
			if v > bv:
				bv = v
				best = g
	return best


func _yesno(e: WWEngine, req: Dictionary) -> bool:
	match str(req.get("why", "")):
		"enigma":
			return int(e.S["mor"][GER]) >= 1 or int(e.S["pv"][GER]) >= 2
		"econ":
			return int(e.S["mor"][GER]) >= 2 or (int(e.S["part"]) == 2 and int(e.S["mor"][GER]) >= 1)
		"rorg":
			return int(e.S["pv"][GER]) >= 4 and _rounds_left(e.S) > 2
	return false


# ------------------------------------------------------------------ decisioni vere (con simulazione)

func decide(e: WWEngine, f: int, req: Dictionary):
	var t := str(req.get("type", ""))
	if t == "turn" and level > 0:
		return _sim_turn(e, f, req)
	if t == "use_gift" and level > 0:
		return _sim_gift_use(e, f, req)
	return _quick(e, f, req)


func _noise() -> float:
	if level >= 2:
		return 0.0
	return (rng.randf() - 0.5) * (1.2 if level == 1 else 4.0)


func _sim_turn(e: WWEngine, f: int, req: Dictionary) -> Dictionary:
	var cands := []
	for p in req["pawns"]:
		if int(req["self_left"]) > 0:
			for u in e.legal_uses(f, p, false):
				cands.append({"m": {"k": "self", "p": p, "use": u}, "q": use_score(e, f, p, false, u)})
		if int(req["gift_left"]) > 0:
			for to in e.gift_targets(f, p):
				cands.append({"m": {"k": "gift", "p": p, "to": to}, "q": -_gift_cost(e, f, p, to) + 2.0})
	if int(req["gift_left"]) > 0 and not req["can_gift"]:
		for p in req["pawns"]:
			cands.append({"m": {"k": "gdisc", "p": p}, "q": -_pawn_worth(e, f, p)})
	if req.has("rfin"):
		for c in req["rfin"]:
			cands.append({"m": {"k": "rfin", "c": c}, "q": 0.5})
	if cands.is_empty():
		return _quick_turn(e, f, req)
	cands.sort_custom(func(a, b): return a["q"] > b["q"])
	var keep := 30 if level >= 2 else 16
	var base := utility(e, f)
	var best = cands[0]["m"]
	var bv := -1e9
	for k in mini(keep, cands.size()):
		var m: Dictionary = cands[k]["m"]
		var x := e.clone_sim(Callable(self, "policy"))
		_play(x, f, m)
		var v := utility(x, f) - base + _noise()
		# chi deve ancora regalare non rimanda all'infinito: piccola spinta verso il regalo meno costoso
		if m["k"] == "gift" and int(req["self_left"]) == 0:
			v += 0.2
		if v > bv:
			bv = v
			best = m
	return best


func _play(x: WWEngine, f: int, m: Dictionary) -> void:
	match str(m["k"]):
		"self":
			x.apply_use(f, int(m["p"]), false, m["use"])
		"gift":
			var p := int(m["p"])
			var to := int(m["to"])
			x.S["start"][f].erase(p)
			x.S["loc"][p] = "gift"
			var uses := x.legal_uses(to, p, true)
			var u = _quick(x, to, {"type": "use_gift", "p": p, "options": uses})
			if u == null:
				u = uses[0]
			x.apply_use(to, p, true, u)
		"gdisc":
			x.S["start"][f].erase(int(m["p"]))
			x.S["loc"][int(m["p"])] = "disc"
		"rfin":
			x.S["cards"].erase(int(m["c"]))
			x.gain_ric(1)


func _sim_gift_use(e: WWEngine, f: int, req: Dictionary):
	var p := int(req["p"])
	var uses: Array = req["options"]
	if uses.size() == 1:
		return uses[0]
	var ranked := []
	for u in uses:
		ranked.append({"u": u, "q": use_score(e, f, p, true, u)})
	ranked.sort_custom(func(a, b): return a["q"] > b["q"])
	var base := utility(e, f)
	var best = ranked[0]["u"]
	var bv := -1e9
	for k in mini(14 if level >= 2 else 8, ranked.size()):
		var x := e.clone_sim(Callable(self, "policy"))
		x.apply_use(f, p, true, ranked[k]["u"])
		var v := utility(x, f) - base + _noise()
		if v > bv:
			bv = v
			best = ranked[k]["u"]
	return best
