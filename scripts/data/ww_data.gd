## Dati di WunderWaffen: territori, pedine, tracciati, carte Ricerca (generato da strumenti/gen_data.py).
class_name WWData
extends RefCounted

const GER := 0
const USSR := 1
const USA := 2
const UK := 3
const FAC_KEY := ["ger", "ussr", "usa", "uk"]
const FAC_NAME := ["Germania", "Unione Sovietica", "Stati Uniti", "Regno Unito"]
const FAC_SHORT := ["tedesco", "sovietico", "americano", "britannico"]
const FAC_COLOR := [Color("#8b8d8a"), Color("#c3392c"), Color("#2e6497"), Color("#ad8a2a")]
const FAC_DARK := [Color("#3e403d"), Color("#7c1d16"), Color("#183d63"), Color("#6b5414")]

# tipi di pedina
const FAN := 1
const COR := 2
const AVI := 3
const ART := 4
const SIM := 5
const POL := 6
const MOR := 7
const MOR2 := 8
const RIC := 9
const RIC2 := 10
const EVE := 11
const TYPE_NAME := ["", "Fanteria", "Corazzati", "Aviazione", "Artiglieria", "Simbolo Fazione", "Politica", "Morale", "Morale Doppio", "Ricerca", "Ricerca Doppia", "Eventi"]
const TYPE_SHORT := ["", "FAN", "COR", "AVI", "ART", "SIM", "POL", "MOR", "MOR×2", "RIC", "RIC×2", "EVE"]
## forza sulle caselle dei Territori (0 = non si piazza)
const STRENGTH := [0, 1, 2, 3, 4, 5, 0, 0, 0, 0, 0, 0]

## pedine: id = fazione*18 + k (k come nel foglio di scansione); immagine assets/pawns/<fazione><k>_f/_b.png
const P_FRONT := [AVI, COR, FAN, RIC, SIM, MOR2, AVI, RIC2, SIM, ART, RIC, FAN, FAN, FAN, ART, COR, RIC, FAN, POL, AVI, FAN, COR, ART, FAN, COR, MOR, SIM, COR, ART, MOR, AVI, FAN, FAN, SIM, FAN, FAN, POL, ART, AVI, FAN, COR, AVI, MOR, FAN, SIM, SIM, MOR, POL, FAN, FAN, FAN, FAN, COR, ART, POL, ART, FAN, FAN, COR, AVI, SIM, AVI, POL, MOR, FAN, FAN, ART, SIM, AVI, FAN, MOR, COR]
const P_BACK := [FAN, FAN, SIM, SIM, COR, SIM, COR, SIM, FAN, EVE, EVE, EVE, MOR, SIM, FAN, FAN, SIM, COR, FAN, FAN, SIM, FAN, FAN, SIM, FAN, EVE, COR, SIM, SIM, FAN, FAN, COR, AVI, AVI, MOR, RIC, FAN, FAN, FAN, SIM, FAN, FAN, FAN, AVI, AVI, COR, EVE, SIM, SIM, RIC, COR, MOR, SIM, RIC, FAN, FAN, SIM, SIM, FAN, FAN, AVI, MOR, MOR, FAN, RIC, COR, SIM, COR, RIC, AVI, EVE, SIM]
## a chi va il retro: [fazione], [-1] = qualsiasi Alleato (simbolo verde), [a, b] = uno dei due
const P_BACK_TO := [[2], [2], [2], [2], [2], [1], [1], [1], [1], [-1], [-1], [-1], [-1], [3], [3], [3], [3], [3], [2], [2], [2], [2], [3], [3], [3], [2, 3], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [1], [1], [1], [1], [3], [3], [0], [0], [0], [0], [1, 3], [0], [3], [0], [0], [0], [0], [0], [1], [1], [1], [2], [2], [2], [0], [0], [0], [0], [0], [0], [0], [0], [0], [0], [2, 1], [0]]

const T_KEY := ["hamburg", "peenemunde", "stettin", "danzig", "brest", "koln", "hannover", "magdeburg", "berlin", "poznan", "warsaw", "leipzig", "breslau", "lodz", "lvov", "frankfurt", "nurnberg", "prague", "katowice", "krakow", "stuttgart", "munchen", "wien"]
const T_NAME := ["Hamburg", "Peenemünde", "Stettin", "Danzig", "Brest-Litovsk", "Köln", "Hannover", "Magdeburg", "Berlino", "Poznan", "Warsaw", "Leipzig", "Breslau", "Lodz", "Lvov", "Frankfurt", "Nürnberg", "Prague", "Katowice", "Krakow", "Stuttgart", "München", "Wien"]
const BERLIN := 8
const T_ADJ := [[1, 7, 6, 5], [0, 2, 7, 8], [1, 8, 9, 3], [2, 9, 10, 4], [3, 10, 14], [0, 6, 15], [0, 5, 7, 11, 15, 16], [0, 1, 8, 6, 11], [1, 2, 9, 12, 11, 7], [2, 3, 10, 13, 12, 8], [3, 4, 14, 13, 9], [7, 8, 12, 6, 16, 17], [8, 9, 13, 17, 11], [9, 10, 14, 18, 12], [4, 10, 13, 19], [5, 6, 16, 20], [15, 6, 11, 17, 21, 20], [12, 16, 18, 21, 22, 11], [13, 17, 19, 22], [14, 18, 22], [15, 16, 21], [20, 16, 17, 22], [21, 17, 18, 19]]
## simboli richiesti dalle tre caselle (0 libera, 2 Corazzati, 3 Aviazione, 4 Artiglieria)
const T_SLOTS := [[2, 3, 0], [2, 3, 0], [4, 0, 0], [3, 0, 0], [2, 0, 0], [2, 2, 0], [2, 0, 0], [4, 0, 0], [], [2, 0, 3], [2, 4, 0], [3, 0, 0], [2, 3, 0], [2, 0, 0], [2, 3, 0], [2, 3, 0], [2, 0, 0], [2, 3, 0], [2, 4, 0], [4, 0, 0], [2, 4, 0], [2, 0, 0], [2, 3, 0]]
## posizioni (frazione del tabellone): centro x, y, larghezza, altezza
const T_SLOT_POS := [[Rect2(0.08277999999999999, 0.10778, 0.03778, 0.03722), Rect2(0.12611, 0.10722, 0.03778, 0.03778), Rect2(0.17, 0.10722, 0.03778, 0.03778)], [Rect2(0.30167, 0.12666499999999997, 0.03778, 0.03833), Rect2(0.345, 0.12666499999999997, 0.03778, 0.03833), Rect2(0.38833, 0.12722, 0.03778, 0.03778)], [Rect2(0.49999999999999994, 0.11333, 0.03778, 0.03778), Rect2(0.54389, 0.11333, 0.03722, 0.03778), Rect2(0.58722, 0.11333, 0.03722, 0.03778)], [Rect2(0.671115, 0.18389499999999998, 0.03833, 0.03833), Rect2(0.7150000000000001, 0.18389499999999998, 0.03778, 0.03833), Rect2(0.757775, 0.18389499999999998, 0.03833, 0.03833)], [Rect2(0.8433350000000001, 0.145005, 0.03833, 0.03833), Rect2(0.8433350000000001, 0.18833499999999997, 0.03833, 0.03833), Rect2(0.886665, 0.18833499999999997, 0.03833, 0.03833)], [Rect2(0.04722, 0.25722, 0.03778, 0.03778), Rect2(0.04722, 0.30055, 0.03778, 0.03778), Rect2(0.09054999999999999, 0.30055, 0.03778, 0.03778)], [Rect2(0.19111, 0.37889500000000004, 0.03778, 0.03833), Rect2(0.19111499999999998, 0.422225, 0.03833, 0.03833), Rect2(0.23444500000000001, 0.422225, 0.03833, 0.03833)], [Rect2(0.271665, 0.23278000000000001, 0.04111, 0.04056), Rect2(0.273885, 0.27555999999999997, 0.03889, 0.03944), Rect2(0.31722500000000003, 0.276115, 0.03889, 0.03889)], [], [Rect2(0.598335, 0.251665, 0.03889, 0.03889), Rect2(0.554445, 0.295005, 0.03833, 0.03833), Rect2(0.597775, 0.294995, 0.03889, 0.03889)], [Rect2(0.6605500000000001, 0.294445, 0.03778, 0.03833), Rect2(0.70389, 0.294445, 0.03778, 0.03833), Rect2(0.747225, 0.294445, 0.03833, 0.03833)], [Rect2(0.32333500000000004, 0.436665, 0.03833, 0.03833), Rect2(0.32388999999999996, 0.48, 0.03778, 0.03778), Rect2(0.366665, 0.480555, 0.03833, 0.03889)], [Rect2(0.456115, 0.48611499999999996, 0.03833, 0.03833), Rect2(0.49833500000000003, 0.48611499999999996, 0.03889, 0.03833), Rect2(0.54111, 0.485555, 0.04, 0.03889)], [Rect2(0.63, 0.44833, 0.03778, 0.03778), Rect2(0.67333, 0.44833500000000004, 0.03778, 0.03833), Rect2(0.71667, 0.44833500000000004, 0.03778, 0.03833)], [Rect2(0.81667, 0.5105500000000001, 0.03778, 0.03778), Rect2(0.81667, 0.55389, 0.03778, 0.03778), Rect2(0.86, 0.55389, 0.03778, 0.03778)], [Rect2(0.05778, 0.6505500000000001, 0.03778, 0.03778), Rect2(0.101115, 0.6505500000000001, 0.03833, 0.03778), Rect2(0.144445, 0.6505500000000001, 0.03833, 0.03778)], [Rect2(0.25222500000000003, 0.633895, 0.03833, 0.03833), Rect2(0.295555, 0.6338900000000001, 0.03833, 0.03778), Rect2(0.33943999999999996, 0.6338900000000001, 0.03778, 0.03778)], [Rect2(0.43444, 0.62333, 0.03778, 0.03778), Rect2(0.47778, 0.62333, 0.03778, 0.03778), Rect2(0.521115, 0.62333, 0.03833, 0.03778)], [Rect2(0.5961150000000001, 0.6622250000000001, 0.03833, 0.03833), Rect2(0.64, 0.6622250000000001, 0.03778, 0.03833), Rect2(0.68333, 0.6622250000000001, 0.03778, 0.03833)], [Rect2(0.7866700000000001, 0.762775, 0.03778, 0.03833), Rect2(0.830005, 0.7633300000000001, 0.03833, 0.03778), Rect2(0.8738900000000001, 0.7633300000000001, 0.03778, 0.03778)], [Rect2(0.11555, 0.8244400000000001, 0.03778, 0.03778), Rect2(0.15944, 0.8244400000000001, 0.03778, 0.03778), Rect2(0.20278000000000002, 0.823895, 0.03778, 0.03833)], [Rect2(0.31611, 0.81222, 0.03778, 0.03778), Rect2(0.359445, 0.81222, 0.03833, 0.03778), Rect2(0.40332999999999997, 0.81222, 0.03778, 0.03778)], [Rect2(0.58611, 0.79278, 0.03778, 0.03778), Rect2(0.62944, 0.79278, 0.03778, 0.03778), Rect2(0.67278, 0.79278, 0.03778, 0.03778)]]
const T_CTRL_POS := [Rect2(0.08222, 0.15056, 0.03944, 0.03889), Rect2(0.32667, 0.19389, 0.03778, 0.03778), Rect2(0.52499, 0.15666, 0.03889, 0.03889), Rect2(0.67167, 0.22778, 0.03778, 0.03722), Rect2(0.84389, 0.23222, 0.03778, 0.03722), Rect2(0.04722, 0.3439, 0.03778, 0.03833), Rect2(0.19111, 0.46611, 0.03833, 0.03278), Rect2(0.27444, 0.32056, 0.03778, 0.03722), Rect2(), Rect2(0.53778, 0.36278, 0.03722, 0.03722), Rect2(0.68611, 0.36167, 0.03722, 0.03778), Rect2(0.32333, 0.52333, 0.03667, 0.03667), Rect2(0.48167, 0.53055, 0.03667, 0.03667), Rect2(0.65555, 0.51555, 0.03778, 0.03778), Rect2(0.81667, 0.59723, 0.03778, 0.03833), Rect2(0.05778, 0.6939, 0.03778, 0.03833), Rect2(0.25222, 0.70111, 0.03778, 0.03778), Rect2(0.43444, 0.69056, 0.03778, 0.03722), Rect2(0.59611, 0.70611, 0.03778, 0.03722), Rect2(0.81222, 0.80612, 0.03778, 0.03833), Rect2(0.11556, 0.86778, 0.03833, 0.03778), Rect2(0.31611, 0.87944, 0.03778, 0.03778), Rect2(0.61111, 0.88444, 0.03778, 0.03778)]
const T_TILE_POS := [Rect2(0.12833, 0.15056, 0.05556, 0.03889), Rect2(0.37111, 0.19389, 0.05556, 0.03778), Rect2(0.57055, 0.15666, 0.05556, 0.03889), Rect2(0.71611, 0.22778, 0.05556, 0.03722), Rect2(0.88833, 0.23222, 0.05556, 0.03722), Rect2(0.09166, 0.3439, 0.05556, 0.03833), Rect2(0.23611, 0.46611, 0.05556, 0.03278), Rect2(0.31889, 0.32056, 0.05556, 0.03722), Rect2(), Rect2(0.58166, 0.36278, 0.05556, 0.03722), Rect2(0.73, 0.36167, 0.05556, 0.03778), Rect2(0.36666, 0.52333, 0.05556, 0.03667), Rect2(0.525, 0.53055, 0.05556, 0.03667), Rect2(0.7, 0.51555, 0.05556, 0.03778), Rect2(0.86111, 0.59723, 0.05556, 0.03833), Rect2(0.10222, 0.6939, 0.05556, 0.03833), Rect2(0.29666, 0.70111, 0.05556, 0.03778), Rect2(0.47889, 0.69056, 0.05556, 0.03722), Rect2(0.64055, 0.70611, 0.05556, 0.03722), Rect2(0.85666, 0.80612, 0.05556, 0.03833), Rect2(0.16055, 0.86778, 0.05556, 0.03778), Rect2(0.36055, 0.87944, 0.05556, 0.03778), Rect2(0.65555, 0.88444, 0.05556, 0.03778)]
const T_CENTER := [Vector2(0.13438, 0.13715), Vector2(0.35931, 0.16264), Vector2(0.55792, 0.14319), Vector2(0.72292, 0.21389), Vector2(0.8734, 0.2075), Vector2(0.07694, 0.31951), Vector2(0.22104, 0.44083), Vector2(0.30389, 0.29576), Vector2(0.46111111111111114, 0.3333333333333333), Vector2(0.59125, 0.32028), Vector2(0.71833, 0.33035), Vector2(0.35319, 0.4991), Vector2(0.51354, 0.51611), Vector2(0.68778, 0.48417), Vector2(0.84639, 0.57285), Vector2(0.10931, 0.68035), Vector2(0.30389, 0.66965), Vector2(0.4859, 0.65896), Vector2(0.64785, 0.69222), Vector2(0.84465, 0.79292), Vector2(0.16729, 0.8541), Vector2(0.36771, 0.84792), Vector2(0.64375, 0.83458)]
## aree di partenza: territori adiacenti e caselle
const START_ADJ := [[], [4, 14], [21, 22], [5, 15]]
const START_POS := [[], [Rect2(0.91111, 0.34111, 0.03778, 0.03778), Rect2(0.91111, 0.38444, 0.03778, 0.03778), Rect2(0.91111, 0.42778, 0.03778, 0.03778)], [Rect2(0.45722, 0.91111, 0.03778, 0.03778), Rect2(0.50055, 0.91111, 0.03778, 0.03778), Rect2(0.54389, 0.91111, 0.03778, 0.03778)], [Rect2(0.05111, 0.45667, 0.03778, 0.03778), Rect2(0.05111, 0.50166, 0.03778, 0.03611), Rect2(0.05111, 0.54389, 0.03778, 0.03778)]]
## caselle di Berlino: 6, 5, 4, 3, 2, 1∞ PV
const BER_POS := [Rect2(0.42055, 0.27055, 0.03778, 0.03778), Rect2(0.46389, 0.27055, 0.03556, 0.03778), Rect2(0.42055, 0.31444, 0.03778, 0.03778), Rect2(0.46389, 0.31389, 0.03556, 0.03778), Rect2(0.42055, 0.35778, 0.03778, 0.03778), Rect2(0.46389, 0.35778, 0.03778, 0.03778)]
const BER_PV := [6, 5, 4, 3, 2, 1]
const BER_BONUS := ["pol", "pol", "mor", "mor", "", ""]
## Conferenza: avanza Politica, 2 PV, avanza Morale
const CONF_POS := [Rect2(0.47056, 0.01166, 0.03833, 0.03833), Rect2(0.51444, 0.01222, 0.03778, 0.03778), Rect2(0.55778, 0.01222, 0.03778, 0.03778)]
const CONF_BONUS := ["pol", "pv2", "mor"]
const POL_POS := [Rect2(0.12333, 0.01222, 0.03667, 0.03667), Rect2(0.17111, 0.01167, 0.03778, 0.03778), Rect2(0.22555, 0.01167, 0.03778, 0.03778), Rect2(0.28, 0.01167, 0.03778, 0.03778), Rect2(0.33444, 0.01167, 0.03778, 0.03778)]
const MOR_POS := [Rect2(0.69444, 0.01222, 0.03667, 0.03667), Rect2(0.74222, 0.01222, 0.03778, 0.03778), Rect2(0.79667, 0.01222, 0.03778, 0.03778), Rect2(0.85055, 0.01222, 0.03778, 0.03778), Rect2(0.905, 0.01222, 0.03778, 0.03778)]
## PV per ogni conquista secondo la posizione sul tracciato del Morale
const MOR_PV := [0, 1, 2, 3, 4]
const PV_POS := [Vector2(0.97944, 0.02056), Vector2(0.97944, 0.05891), Vector2(0.97944, 0.09727), Vector2(0.97944, 0.13562), Vector2(0.97944, 0.17398), Vector2(0.97944, 0.21233), Vector2(0.97944, 0.25069), Vector2(0.97944, 0.28904), Vector2(0.97944, 0.3274), Vector2(0.97944, 0.36576), Vector2(0.97944, 0.40411), Vector2(0.97944, 0.44247), Vector2(0.97944, 0.48082), Vector2(0.97944, 0.51918), Vector2(0.97944, 0.55753), Vector2(0.97944, 0.59589), Vector2(0.97944, 0.63424), Vector2(0.97944, 0.6726), Vector2(0.97944, 0.71096), Vector2(0.97944, 0.74931), Vector2(0.97944, 0.78767), Vector2(0.97944, 0.82602), Vector2(0.97944, 0.86438), Vector2(0.97944, 0.90273), Vector2(0.97944, 0.94109), Vector2(0.97944, 0.97944), Vector2(0.94109, 0.97944), Vector2(0.90273, 0.97944), Vector2(0.86438, 0.97944), Vector2(0.82602, 0.97944), Vector2(0.78767, 0.97944), Vector2(0.74931, 0.97944), Vector2(0.71096, 0.97944), Vector2(0.6726, 0.97944), Vector2(0.63424, 0.97944), Vector2(0.59589, 0.97944), Vector2(0.55753, 0.97944), Vector2(0.51918, 0.97944), Vector2(0.48082, 0.97944), Vector2(0.44247, 0.97944), Vector2(0.40411, 0.97944), Vector2(0.36576, 0.97944), Vector2(0.3274, 0.97944), Vector2(0.28904, 0.97944), Vector2(0.25069, 0.97944), Vector2(0.21233, 0.97944), Vector2(0.17398, 0.97944), Vector2(0.13562, 0.97944), Vector2(0.09727, 0.97944), Vector2(0.05891, 0.97944), Vector2(0.02056, 0.97944), Vector2(0.02056, 0.94109), Vector2(0.02056, 0.90273), Vector2(0.02056, 0.86438), Vector2(0.02056, 0.82602), Vector2(0.02056, 0.78767), Vector2(0.02056, 0.74931), Vector2(0.02056, 0.71096), Vector2(0.02056, 0.6726), Vector2(0.02056, 0.63424), Vector2(0.02056, 0.59589), Vector2(0.02056, 0.55753), Vector2(0.02056, 0.51918), Vector2(0.02056, 0.48082), Vector2(0.02056, 0.44247), Vector2(0.02056, 0.40411), Vector2(0.02056, 0.36576), Vector2(0.02056, 0.3274), Vector2(0.02056, 0.28904), Vector2(0.02056, 0.25069), Vector2(0.02056, 0.21233), Vector2(0.02056, 0.17398), Vector2(0.02056, 0.13562), Vector2(0.02056, 0.09727), Vector2(0.02056, 0.05891), Vector2(0.02056, 0.02056)]
const PV_CELL := 0.03667

## tessere Territorio: PV e bonus (ric, pol, mor, eve, card); immagine assets/tiles/tNN.png
const TILE_PV := [2, 3, 1, 2, 0, 1, 2, 2, 4, 3, 4, 2, 2, 3, 2, 2, 4, 1, 2, 0, 1, 0, 1, 3]
const TILE_BONUS := [["ric"], [], ["pol"], [], ["pol", "ric"], ["pol"], [], ["eve"], [], [], [], ["pol"], ["mor"], [], [], [], [], ["ric"], ["eve"], ["card"], ["eve"], ["mor", "eve"], ["mor"], []]
## preparazione storica (pag. 18-19): tessera per territorio, -1 per Berlino
const HIST_TILES := [1, 0, 8, 9, 7, 21, 3, 13, -1, 19, 6, 20, 11, 22, 14, 2, 23, 15, 18, 10, 4, 5, 12]

## ------------------------------------------------------------------ tracciati Eventi degli Alleati
## Ogni casella: nome, pedine che si possono scartare per arrivarci, e le due opzioni (sinistra/destra
## sulla scheda). Un effetto è [tipo, chi, quanto]: tipo pv / mor / pol / ric; chi "self", "ger", "usa",
## "ussr", "uk" oppure "any" (simbolo verde: decide chi avanza il segnalino).
const EVENTS := {
	3: [
		{"name": "Operazione Overlord", "req": [FAN, AVI], "opt": [[["mor", "ger", -1], ["pv", "self", 2]], [["mor", "self", 1], ["pv", "usa", 3]]]},
		{"name": "Operazione Cobra", "req": [ART, AVI], "opt": [[["mor", "ger", -1], ["pv", "self", 3]], [["pol", "self", 1]]]},
		{"name": "Operazione Market-Garden", "req": [FAN, AVI], "opt": [[["mor", "ger", 1]], [["mor", "usa", -1], ["mor", "self", -1]]]},
		{"name": "Presa del porto di Anversa", "req": [COR], "opt": [[["mor", "ger", -1], ["pv", "self", 4]], [["mor", "self", 1], ["pv", "self", 3]]]},
		{"name": "Operazione Veritable", "req": [ART, AVI], "opt": [[["ric", "ger", -1], ["pv", "self", 3]], [["pol", "self", 1], ["pv", "self", 3]]]},
		{"name": "Bombardamenti sulla Germania", "req": [ART, AVI], "opt": [[["ric", "ger", -1]], [["pv", "self", 3]]]},
	],
	1: [
		{"name": "Liberazione di Sebastopoli", "req": [FAN, ART], "opt": [[["mor", "ger", -1]], [["mor", "self", 1]]]},
		{"name": "Operazione Bagration", "req": [COR, ART], "opt": [[["mor", "self", 1], ["pv", "self", 2]], [["pol", "self", 1]]]},
		{"name": "Liberazione di Minsk e Vilnius", "req": [ART, AVI], "opt": [[["mor", "ger", -1], ["pv", "self", 4]], [["mor", "self", 1], ["pv", "self", 3]]]},
		{"name": "Sconfitta dell'Ungheria", "req": [COR, AVI], "opt": [[["pol", "ger", -1], ["pv", "self", 3]], [["pol", "self", 1], ["pv", "usa", 3]]]},
		{"name": "Battaglia di Königsberg", "req": [ART, AVI], "opt": [[["ric", "ger", -1], ["pv", "self", 4]], [["mor", "self", 1], ["pv", "self", 3]]]},
		{"name": "Battaglia di Berlino", "req": [COR, ART, AVI], "opt": [[["mor", "ger", -1], ["pv", "self", 2]], [["pv", "self", 3]]]},
	],
	2: [
		{"name": "Sbarchi nel Sud Italia", "req": [ART, AVI], "opt": [[["mor", "ger", -1], ["pv", "self", 2]], [["mor", "self", 1]]]},
		{"name": "Liberazione di Roma", "req": [COR, ART], "opt": [[["mor", "self", 1], ["pv", "self", 3]], [["pol", "self", 1]]]},
		{"name": "Fallimento Operazione Valchiria", "req": [POL, MOR], "opt": [[["pv", "self", -3], ["mor", "ger", -1]], [["mor", "any", -1], ["mor", "any", -1]]]},
		{"name": "Operazione Dragoon", "req": [ART, AVI], "opt": [[["mor", "ger", -1], ["pv", "self", 4]], [["pol", "self", 1]]]},
		{"name": "Incontro tra gli Alleati sull'Elba", "req": [FAN, POL], "opt": [[["pv", "self", 4], ["pv", "ussr", 2]], [["pol", "self", 1], ["mor", "ussr", 1]]]},
		{"name": "Bombardamenti sulla Germania", "req": [ART, AVI], "opt": [[["pv", "self", 2], ["pv", "ger", -2]], [["pv", "self", 3]]]},
	],
}

## ------------------------------------------------------------------ carte Ricerca (assets/cards/cNN.jpg)
## lvl valore; pv/pol/mor bonus all'acquisto; atom/rocket simboli; once = fulmine (effetto immediato).
const CARDS := [
	{"key": "v1", "name": "Bomba V1", "lvl": 1, "pv": 3, "pol": 0, "mor": 0, "atom": 0, "rocket": 1, "once": false,
		"text": "Quando utilizzi una pedina Artiglieria, un giocatore Alleato a tua scelta perde 1 Morale e tu ottieni 1 Morale."},
	{"key": "jet", "name": "Aerei a reazione", "lvl": 1, "pv": 0, "pol": 1, "mor": 1, "atom": 0, "rocket": 0, "once": false,
		"text": "Quando piazzi una pedina Aviazione sulla tua scheda Fazione, un giocatore Alleato a tua scelta deve scartare una pedina Aviazione dalla sua area di partenza."},
	{"key": "rfin", "name": "Ricerca finalizzata", "lvl": 1, "pv": 0, "pol": 0, "mor": 1, "atom": 0, "rocket": 0, "once": false,
		"text": "In qualsiasi momento del tuo turno puoi scartare una tua carta Ricerca di valore 1 (compresa questa) per avanzare di 1 posizione sul tracciato Ricerca."},
	{"key": "acqua", "name": "Acqua pesante", "lvl": 1, "pv": 1, "pol": 1, "mor": 1, "atom": 1, "rocket": 0, "once": false,
		"text": "Raggiunto un importante obiettivo per la realizzazione della bomba atomica."},
	{"key": "gen", "name": "Sostituzione dei generali", "lvl": 1, "pv": 0, "pol": 0, "mor": 0, "atom": 0, "rocket": 0, "once": true,
		"text": "Scegli due pedine dai tuoi scarti e sostituiscile con due pedine della tua riserva."},
	{"key": "ala", "name": "Bombardieri a tutt'ala", "lvl": 1, "pv": 0, "pol": 0, "mor": 0, "atom": 0, "rocket": 0, "once": false,
		"text": "Quando utilizzi una pedina Aviazione o Artiglieria, un giocatore Alleato a tua scelta deve scartare una pedina Fanteria o Corazzati dalla sua area di partenza."},
	{"key": "mecc", "name": "Truppe meccanizzate", "lvl": 1, "pv": 3, "pol": 0, "mor": 1, "atom": 0, "rocket": 0, "once": false,
		"text": "Puoi piazzare una pedina Fanteria tedesca come se la sua forza fosse pari a quella di una pedina Corazzati."},
	{"key": "sci", "name": "Scienziati", "lvl": 1, "pv": 1, "pol": 1, "mor": 1, "atom": 2, "rocket": 1, "once": false,
		"text": "Gli scienziati tedeschi sono convinti a restare in Germania per servire la patria."},
	{"key": "prop", "name": "Contro propaganda", "lvl": 2, "pv": 0, "pol": 1, "mor": 0, "atom": 0, "rocket": 0, "once": true,
		"text": "Ogni giocatore Alleato deve scegliere e scartare una pedina dalla sua area di partenza."},
	{"key": "rorg", "name": "Ricerca organizzata", "lvl": 2, "pv": 0, "pol": 0, "mor": 0, "atom": 0, "rocket": 0, "once": false,
		"text": "Dopo aver acquisito una carta, riporta normalmente il segnalino Ricerca sulla prima casella; poi puoi decidere di perdere 2 PV per avanzare di una posizione."},
	{"key": "carri", "name": "Carri armati pesanti", "lvl": 2, "pv": 0, "pol": 1, "mor": 1, "atom": 0, "rocket": 0, "once": false,
		"text": "Durante la seconda parte del gioco, quando piazzi una pedina Corazzati sulla tua scheda Fazione, ogni giocatore Alleato deve scartare una pedina Corazzati dalla sua area di partenza."},
	{"key": "uboot", "name": "Super U-Boot", "lvl": 2, "pv": 0, "pol": 0, "mor": 0, "atom": 0, "rocket": 0, "once": true,
		"text": "Utilizza una tua pedina scartata per trasformare in Fortezza un Territorio non conquistato a scelta tra Danzig, Stettin, Peenemünde, Hamburg o Köln. Ottieni la tessera Territorio e i relativi PV normalmente."},
	{"key": "v2", "name": "Bomba V2", "lvl": 2, "pv": 3, "pol": 0, "mor": 0, "atom": 0, "rocket": 1, "once": false,
		"text": "Quando utilizzi una pedina Artiglieria, un giocatore Alleato a tua scelta perde 1 Politica e tu ottieni 2 PV."},
	{"key": "spie", "name": "Rete di spie", "lvl": 2, "pv": 0, "pol": 0, "mor": 0, "atom": 0, "rocket": 0, "once": false,
		"text": "Quando un avversario Alleato utilizza una pedina Politica, puoi guardare i retri delle pedine alleate piazzate sulle aree di partenza. Poi girane una per giocatore, scegliendo come fargliele giocare."},
	{"key": "uranio", "name": "Progetto Uranio", "lvl": 2, "pv": 4, "pol": 1, "mor": 0, "atom": 1, "rocket": 0, "once": false,
		"text": "Un passo avanti verso la bomba atomica. A fine partita otterrai 2 PV per ogni carta con un simbolo atomo che possiedi."},
	{"key": "braun", "name": "Werner von Braun", "lvl": 2, "pv": 0, "pol": 0, "mor": 0, "atom": 0, "rocket": 1, "once": false,
		"text": "Tutte le carte con simbolo razzo e/o atomo costano un punto Ricerca in meno. A fine partita otterrai 2 PV per ogni carta con un simbolo razzo che possiedi."},
	{"key": "difesa", "name": "Difesa avanzata", "lvl": 3, "pv": 0, "pol": 0, "mor": 1, "atom": 0, "rocket": 0, "once": true,
		"text": "Ottieni 2 PV per ogni Territorio che controlli."},
	{"key": "strat", "name": "Bombardieri strategici", "lvl": 3, "pv": 6, "pol": 1, "mor": 0, "atom": 0, "rocket": 0, "once": false,
		"text": "Quando utilizzi una pedina Aviazione o Artiglieria, ottieni 3 PV."},
	{"key": "atomica", "name": "Bomba atomica", "lvl": 3, "pv": 5, "pol": 1, "mor": 0, "atom": 0, "rocket": 0, "once": true,
		"text": "Devi avere tre simboli atomo visibili sulle carte che possiedi per acquisire questa carta. Ogni giocatore Alleato perde 1 Morale e 1 Politica."},
	{"key": "v3", "name": "Bomba V3", "lvl": 3, "pv": 6, "pol": 0, "mor": 1, "atom": 0, "rocket": 1, "once": false,
		"text": "Quando utilizzi una pedina Artiglieria, un giocatore Alleato a tua scelta perde 2 PV e tu ottieni 2 PV. A fine partita otterrai 1 PV per ogni carta con un simbolo razzo che possiedi."},
	{"key": "enigma", "name": "Enigma 2", "lvl": 3, "pv": 6, "pol": 0, "mor": 0, "atom": 0, "rocket": 0, "once": false,
		"text": "Quando un avversario Alleato utilizza una pedina Simbolo Fazione, puoi perdere 1 Morale per ottenere 4 PV."},
	{"key": "econ", "name": "Economia di guerra", "lvl": 3, "pv": 5, "pol": 1, "mor": 0, "atom": 0, "rocket": 0, "once": false,
		"text": "Al termine del tuo turno puoi perdere 1 Morale per ottenere 5 PV."},
	{"key": "gustav", "name": "Langer Gustav", "lvl": 3, "pv": 0, "pol": 0, "mor": 0, "atom": 0, "rocket": 1, "once": true,
		"text": "Utilizza due tue pedine scartate per trasformare in Fortezze due Territori non conquistati. Ottieni le tessere Territorio e i relativi PV normalmente."},
	{"key": "visita", "name": "Visita dei generali", "lvl": 3, "pv": 6, "pol": 0, "mor": 0, "atom": 0, "rocket": 0, "once": true,
		"text": "Ottieni un totale di 3 Morale e/o Politica, che puoi assegnare come preferisci. Poi ottieni 2 PV per ogni pedina Fanteria tedesca in un Territorio non conquistato."},
]
## Territori che il Super U-Boot può trasformare in Fortezza
const UBOOT_TERR := ["danzig", "stettin", "peenemunde", "hamburg", "koln"]
## punti Ricerca disponibili per posizione sul tracciato (0 = casella di partenza)
const RIC_POINTS := [0, 0, 1, 2, 3, 3]
const RIC_MAX := 5
## ordine di gioco (anche per la partita a due)
const ORDER := [GER, USSR, USA, UK]


static func card_index(key: String) -> int:
	for i in CARDS.size():
		if CARDS[i]["key"] == key:
			return i
	return -1


static func t_index(key: String) -> int:
	return T_KEY.find(key)


static func pawn_tex_path(pid: int, back: bool) -> String:
	return "res://assets/pawns/%s%02d_%s.png" % [FAC_KEY[pid / 18], pid % 18, "b" if back else "f"]


static func owner(pid: int) -> int:
	return pid / 18
