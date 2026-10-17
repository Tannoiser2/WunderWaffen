import sys,json; sys.path.insert(0,'.')
from orient_lib import *
sys.path.insert(0,'data')
# tipi dal file dati
import re
src=open('/home/claude/wunderwaffen/scripts/data/ww_data.gd').read()
def arr(name):
    m=re.search(r'const '+name+r' := \[(.*)\]\n',src); return [x.strip() for x in m.group(1).split(',')]
FR=arr('P_FRONT'); BK=arr('P_BACK')
TO=json.loads('['+re.search(r'const P_BACK_TO := \[(.*)\]\n',src).group(1)+']')
FK=['ger','ussr','usa','uk']
def mask(t):
    t=cv2.GaussianBlur(t,(3,3),0).astype(np.float32)
    ring=np.concatenate([t[30:40,30:182].reshape(-1,3),t[172:182,30:182].reshape(-1,3),t[30:182,30:40].reshape(-1,3),t[30:182,172:182].reshape(-1,3)])
    bg=np.median(ring,0)
    d=np.abs(t-bg).sum(2)
    m=(d>60).astype(np.uint8)
    m[:28]=0;m[-28:]=0;m[:,:28]=0;m[:,-28:]=0
    m=cv2.morphologyEx(m,cv2.MORPH_OPEN,np.ones((3,3),np.uint8))
    return m
def norm(m):
    ys,xs=np.where(m>0)
    if len(xs)<50: return np.zeros((64,64),np.float32)
    cy,cx=ys.mean(),xs.mean(); r=np.sqrt(len(xs))*0.9
    M=np.float32([[32/r,0,32-cx*32/r],[0,32/r,32-cy*32/r]])
    return cv2.warpAffine(m.astype(np.float32),M,(64,64))
items=[]
for f in range(4):
    fac=FK[f]
    for k in range(18):
        pid=f*18+k; r,c=rc(fac,k)
        for side,im,typ in [('f',F,FR[pid]),('b',B,BK[pid])]:
            if side=='f': icf=fac
            else:
                to=TO[pid]
                icf='green' if (to==[-1] or (typ in('EVE','MOR') and len(to)>1)) else FK[to[0]]
                if typ=='EVE' and to!=[-1]: icf='evepair'
                if typ=='MOR' and to==[-1]: icf='green'
            key=typ
            if typ in('FAN','SIM'): key=typ+'_'+icf
            if typ=='EVE': key='EVE_'+('green' if to==[-1] else 'pair')
            if typ=='MOR' and side=='b' and to==[-1]: key='MOR_green'
            t=cell(im,r,c)
            items.append(dict(fac=fac,k=k,side=side,key=key,n=norm(mask(t)),img=t))
groups={}
for it in items: groups.setdefault(it['key'],[]).append(it)
def rot(a,q): return np.rot90(a,q).copy()
out={}
ref_sheet=[]
for key,g in sorted(groups.items()):
    ref=g[0]
    for it in g:
        best=max(range(4),key=lambda q: (rot(it['n'],q)*ref['n']).sum()/ (np.sqrt((rot(it['n'],q)**2).sum()*(ref['n']**2).sum())+1e-6))
        sc=[(rot(it['n'],q)*ref['n']).sum()/(np.sqrt((it['n']**2).sum()*(ref['n']**2).sum())+1e-6) for q in range(4)]
        s=sorted(sc)
        it['q']=best; it['conf']=s[-1]-s[-2]
    ref_sheet.append((key,ref['img'],len(g)))
    print(key,len(g),'conf min %.2f'%min(i['conf'] for i in g), [ (i['fac'],i['k'],i['side']) for i in g if i['conf']<0.08])
import pickle; pickle.dump([{k:v for k,v in it.items() if k not in('n',)} for it in items],open('orient_items.pkl','wb'))
tiles=[]
for key,img,n in ref_sheet:
    t=cv2.resize(img,(150,150)); cv2.putText(t,key,(2,14),0,0.45,(0,0,255),1); tiles.append(t)
while len(tiles)%6: tiles.append(np.zeros_like(tiles[0]))
cv2.imwrite('/tmp/claude-0/-home-claude/8c439650-173e-5c5c-a62d-194cf7472e02/scratchpad/refs.jpg',np.vstack([np.hstack(tiles[i:i+6]) for i in range(0,len(tiles),6)]))
