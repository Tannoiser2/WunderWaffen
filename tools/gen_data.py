import json,cv2,numpy as np
d=json.load(open('data/coords_preview.json'))
im=cv2.imread('out/anteprima.jpg'); hsv=cv2.cvtColor(im,cv2.COLOR_BGR2HSV)
light=((hsv[...,2]>175)&(hsv[...,1]<70)).astype(np.uint8)
light=cv2.morphologyEx(light,cv2.MORPH_OPEN,np.ones((5,5),np.uint8))
nl,ll,sl,cl=cv2.connectedComponentsWithStats(light)
def snap(x,y):
    k=0
    for r in range(0,32,2):
        for dx,dy in [(0,0),(r,0),(-r,0),(0,r),(0,-r),(r,r),(-r,-r),(r,-r),(-r,r)]:
            kk=ll[y+dy,x+dx]
            if kk and 1500<sl[kk,4]<15000: k=kk; break
        if k: break
    if k:
        x0,y0,w,h,a=[int(v) for v in sl[k]]; return [x0+w/2,y0+h/2,w,h]
    print('nosnap',x,y); return [x,y,66,66]
S=1800.0
def n(b): return [round(b[0]/S,5),round(b[1]/S,5),round(b[2]/S,5),round(b[3]/S,5)]
IDS=['hamburg','peenemunde','stettin','danzig','brest','koln','hannover','magdeburg','berlin','poznan','warsaw','leipzig','breslau','lodz','lvov','frankfurt','nurnberg','prague','katowice','krakow','stuttgart','munchen','wien']
NAMES={'hamburg':'Hamburg','peenemunde':'Peenemünde','stettin':'Stettin','danzig':'Danzig','brest':'Brest-Litovsk','koln':'Köln','hannover':'Hannover','magdeburg':'Magdeburg','berlin':'Berlino','poznan':'Poznan','warsaw':'Warsaw','leipzig':'Leipzig','breslau':'Breslau','lodz':'Lodz','lvov':'Lvov','frankfurt':'Frankfurt','nurnberg':'Nürnberg','prague':'Prague','katowice':'Katowice','krakow':'Krakow','stuttgart':'Stuttgart','munchen':'München','wien':'Wien'}
ADJ={'hamburg':['peenemunde','magdeburg','hannover','koln'],'peenemunde':['hamburg','stettin','magdeburg','berlin'],'stettin':['peenemunde','berlin','poznan','danzig'],'danzig':['stettin','poznan','warsaw','brest'],'brest':['danzig','warsaw','lvov'],'koln':['hamburg','hannover','frankfurt'],'hannover':['hamburg','koln','magdeburg','leipzig','frankfurt','nurnberg'],'magdeburg':['hamburg','peenemunde','berlin','hannover','leipzig'],'berlin':['peenemunde','stettin','poznan','breslau','leipzig','magdeburg'],'poznan':['stettin','danzig','warsaw','lodz','breslau','berlin'],'warsaw':['danzig','brest','lvov','lodz','poznan'],'leipzig':['magdeburg','berlin','breslau','hannover','nurnberg','prague'],'breslau':['berlin','poznan','lodz','prague','leipzig'],'lodz':['poznan','warsaw','lvov','katowice','breslau'],'lvov':['brest','warsaw','lodz','krakow'],'frankfurt':['koln','hannover','nurnberg','stuttgart'],'nurnberg':['frankfurt','hannover','leipzig','prague','munchen','stuttgart'],'prague':['breslau','nurnberg','katowice','munchen','wien','leipzig'],'katowice':['lodz','prague','krakow','wien'],'krakow':['lvov','katowice','wien'],'stuttgart':['frankfurt','nurnberg','munchen'],'munchen':['stuttgart','nurnberg','prague','wien'],'wien':['munchen','prague','katowice','krakow']}
for a,l in ADJ.items():
    for b in l: assert a in ADJ[b],(a,b)
TYPE={'L':0,'C':2,'A':3,'R':4}
HIST={'hamburg':1,'peenemunde':0,'stettin':8,'danzig':9,'brest':7,'koln':21,'hannover':3,'magdeburg':13,'poznan':19,'warsaw':6,'leipzig':20,'breslau':11,'lodz':22,'lvov':14,'frankfurt':2,'nurnberg':23,'prague':15,'katowice':18,'krakow':10,'stuttgart':4,'munchen':5,'wien':12}
out=[]
out.append('## Dati di WunderWaffen: territori, pedine, tracciati, carte Ricerca (generato da strumenti/gen_data.py).')
out.append('class_name WWData\nextends RefCounted\n')
out.append('const GER := 0\nconst USSR := 1\nconst USA := 2\nconst UK := 3')
out.append('const FAC_KEY := ["ger", "ussr", "usa", "uk"]')
out.append('const FAC_NAME := ["Germania", "Unione Sovietica", "Stati Uniti", "Regno Unito"]')
out.append('const FAC_SHORT := ["tedesco", "sovietico", "americano", "britannico"]')
out.append('const FAC_COLOR := [Color("#8b8d8a"), Color("#c3392c"), Color("#2e6497"), Color("#ad8a2a")]')
out.append('const FAC_DARK := [Color("#3e403d"), Color("#7c1d16"), Color("#183d63"), Color("#6b5414")]')
out.append('\n# tipi di pedina\nconst FAN := 1\nconst COR := 2\nconst AVI := 3\nconst ART := 4\nconst SIM := 5\nconst POL := 6\nconst MOR := 7\nconst MOR2 := 8\nconst RIC := 9\nconst RIC2 := 10\nconst EVE := 11')
out.append('const TYPE_NAME := ["", "Fanteria", "Corazzati", "Aviazione", "Artiglieria", "Simbolo Fazione", "Politica", "Morale", "Morale Doppio", "Ricerca", "Ricerca Doppia", "Eventi"]')
out.append('const TYPE_SHORT := ["", "FAN", "COR", "AVI", "ART", "SIM", "POL", "MOR", "MOR×2", "RIC", "RIC×2", "EVE"]')
out.append('## forza sulle caselle dei Territori (0 = non si piazza)\nconst STRENGTH := [0, 1, 2, 3, 4, 5, 0, 0, 0, 0, 0, 0]')
# pedine
F={'uk':( 'POL ART FAN FAN COR AVI SIM AVI POL MOR FAN FAN ART SIM AVI FAN MOR COR',
          'FAN@ussr FAN@ussr SIM@ussr SIM@usa FAN@usa FAN@usa AVI@ger MOR@ger MOR@ger FAN@ger RIC@ger COR@ger SIM@ger COR@ger RIC@ger AVI@ger EVE@usa/ussr SIM@ger'),
   'ussr':('POL AVI FAN COR ART FAN COR MOR SIM COR ART MOR AVI FAN FAN SIM FAN FAN',
          'FAN@usa FAN@usa SIM@usa FAN@usa FAN@uk SIM@uk FAN@uk EVE@usa/uk COR@ger SIM@ger SIM@ger FAN@ger FAN@ger COR@ger AVI@ger AVI@ger MOR@ger RIC@ger'),
   'usa':('POL ART AVI FAN COR AVI MOR FAN SIM SIM MOR POL FAN FAN FAN FAN COR ART',
          'FAN@ussr FAN@ussr FAN@ussr SIM@ussr FAN@uk FAN@uk FAN@ger AVI@ger AVI@ger COR@ger EVE@ussr/uk SIM@ger SIM@uk RIC@ger COR@ger MOR@ger SIM@ger RIC@ger'),
   'ger':('AVI COR FAN RIC SIM MOR2 AVI RIC2 SIM ART RIC FAN FAN FAN ART COR RIC FAN',
          'FAN@usa FAN@usa SIM@usa SIM@usa COR@usa SIM@ussr COR@ussr SIM@ussr FAN@ussr EVE@any EVE@any EVE@any MOR@any SIM@uk FAN@uk FAN@uk SIM@uk COR@uk')}
FI={'ger':0,'ussr':1,'usa':2,'uk':3}
fr=[];bt=[];bto=[]
for fac in ['ger','ussr','usa','uk']:
    a=F[fac][0].split(); b=F[fac][1].split(); assert len(a)==18 and len(b)==18,fac
    for x in a: fr.append(x)
    for x in b:
        t,to=x.split('@'); bt.append(t)
        if to=='any': bto.append('[-1]')
        elif '/' in to: bto.append('[%d, %d]'%tuple(FI[y] for y in to.split('/')))
        else: bto.append('[%d]'%FI[to])
out.append('\n## pedine: id = fazione*18 + k (k come nel foglio di scansione); immagine assets/pawns/<fazione><k>_f/_b.png')
out.append('const P_FRONT := ['+', '.join(fr)+']')
out.append('const P_BACK := ['+', '.join(bt)+']')
out.append('## a chi va il retro: [fazione], [-1] = qualsiasi Alleato (simbolo verde), [a, b] = uno dei due')
out.append('const P_BACK_TO := ['+', '.join(bto)+']')
# territori
out.append('\nconst T_KEY := '+json.dumps(IDS))
out.append('const T_NAME := '+json.dumps([NAMES[k] for k in IDS],ensure_ascii=False))
out.append('const BERLIN := %d'%IDS.index('berlin'))
out.append('const T_ADJ := ['+', '.join('['+', '.join(str(IDS.index(b)) for b in ADJ[k])+']' for k in IDS)+']')
out.append('## simboli richiesti dalle tre caselle (0 libera, 2 Corazzati, 3 Aviazione, 4 Artiglieria)')
out.append('const T_SLOTS := ['+', '.join('['+', '.join(str(TYPE[s[0]]) for s in d[k]['slot'])+']' if k!='berlin' else '[]' for k in IDS)+']')
out.append('## posizioni (frazione del tabellone): centro x, y, larghezza, altezza')
out.append('const T_SLOT_POS := ['+', '.join('['+', '.join('Rect2(%s)'%', '.join(str(v) for v in [n(s[1:])[0]-n(s[1:])[2]/2,n(s[1:])[1]-n(s[1:])[3]/2,n(s[1:])[2],n(s[1:])[3]]) for s in d[k]['slot'])+']' if k!='berlin' else '[]' for k in IDS)+']')
def R(b): b=n(b); return 'Rect2(%s, %s, %s, %s)'%(round(b[0]-b[2]/2,5),round(b[1]-b[3]/2,5),b[2],b[3])
out.append('const T_CTRL_POS := ['+', '.join(R(d[k]['ctrl']) if k!='berlin' else 'Rect2()' for k in IDS)+']')
out.append('const T_TILE_POS := ['+', '.join(R(d[k]['tile']) if k!='berlin' else 'Rect2()' for k in IDS)+']')
# centro del territorio (per etichette e clic): media delle caselle
cen=[]
for k in IDS:
    if k=='berlin': cen.append((830/S,600/S)); continue
    pts=[s[1:3] for s in d[k]['slot']]+[d[k]['ctrl'][:2]]
    cen.append((round(np.mean([p[0] for p in pts])/S,5),round(np.mean([p[1] for p in pts])/S,5)))
out.append('const T_CENTER := ['+', '.join('Vector2(%s, %s)'%c for c in cen)+']')
out.append('## aree di partenza: territori adiacenti e caselle')
SA={0:[],1:['brest','lvov'],2:['munchen','wien'],3:['koln','frankfurt']}
out.append('const START_ADJ := ['+', '.join('['+', '.join(str(IDS.index(x)) for x in SA[f])+']' for f in range(4))+']')
st={1:d['start_urss'],2:d['start_usa'],3:d['start_uk']}
out.append('const START_POS := [[], '+', '.join('['+', '.join(R(b) for b in st[f])+']' for f in [1,2,3])+']')
# Berlino, Conferenza, tracciati
ber=[snap(*p) for p in [(790,520),(868,520),(790,598),(868,598),(790,676),(868,676)]]
out.append('## caselle di Berlino: 6, 5, 4, 3, 2, 1∞ PV')
out.append('const BER_POS := ['+', '.join(R(b) for b in ber)+']')
out.append('const BER_PV := [6, 5, 4, 3, 2, 1]')
out.append('const BER_BONUS := ["pol", "pol", "mor", "mor", "", ""]')
conf=[snap(*p) for p in [(880,55),(960,55),(1037,55)]]
out.append('## Conferenza: avanza Politica, 2 PV, avanza Morale')
out.append('const CONF_POS := ['+', '.join(R(b) for b in conf)+']')
out.append('const CONF_BONUS := ["pol", "pv2", "mor"]')
pol=[snap(*p) for p in [(255,55),(343,55),(440,55),(538,55),(635,55)]]
mor=[snap(*p) for p in [(1283,55),(1370,55),(1467,55),(1565,55),(1663,55)]]
out.append('const POL_POS := ['+', '.join(R(b) for b in pol)+']')
out.append('const MOR_POS := ['+', '.join(R(b) for b in mor)+']')
out.append('## PV per ogni conquista secondo la posizione sul tracciato del Morale')
out.append('const MOR_PV := [0, 1, 2, 3, 4]')
pv=[]
for i in range(76):
    if i<=25: x,y=1763,37+69.04*i
    elif i<=50: x,y=1763-69.04*(i-25),1763
    else: x,y=37,1763-69.04*(i-50)
    pv.append('Vector2(%s, %s)'%(round(x/S,5),round(y/S,5)))
out.append('const PV_POS := ['+', '.join(pv)+']')
out.append('const PV_CELL := %s'%round(66/S,5))
# tessere
TL=[(2,['ric']),(3,[]),(1,['pol']),(2,[]),(0,['pol','ric']),(1,['pol']),(2,[]),(2,['eve']),(4,[]),(3,[]),(4,[]),(2,['pol']),(2,['mor']),(3,[]),(2,[]),(2,[]),(4,[]),(1,['ric']),(2,['eve']),(0,['card']),(1,['eve']),(0,['mor','eve']),(1,['mor']),(3,[])]
out.append('\n## tessere Territorio: PV e bonus (ric, pol, mor, eve, card); immagine assets/tiles/tNN.png')
out.append('const TILE_PV := ['+', '.join(str(t[0]) for t in TL)+']')
out.append('const TILE_BONUS := ['+', '.join(json.dumps(t[1]) for t in TL)+']')
out.append('## preparazione storica (pag. 18-19): tessera per territorio, -1 per Berlino')
out.append('const HIST_TILES := ['+', '.join(str(HIST.get(k,-1)) for k in IDS)+']')
open('/home/claude/ww/data/ww_data_part1.gd','w').write('\n'.join(out)+'\n')
print('ok', len(fr))
