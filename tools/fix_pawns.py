import pickle,cv2,numpy as np,sys
sys.path.insert(0,'.')
from orient_lib import *
items=pickle.load(open('orient_items.pkl','rb'))
R='/home/claude/wunderwaffen/assets'
def rounded(img,rad):
    h,w=img.shape[:2]; a=np.zeros((h,w),np.uint8)
    cv2.rectangle(a,(rad,0),(w-rad,h),255,-1); cv2.rectangle(a,(0,rad),(w,h-rad),255,-1)
    for cx,cy in [(rad,rad),(w-rad-1,rad),(rad,h-rad-1),(w-rad-1,h-rad-1)]: cv2.circle(a,(cx,cy),rad,255,-1,cv2.LINE_AA)
    return np.dstack([img,cv2.GaussianBlur(a,(3,3),0)])
from collections import Counter
maj={}
for key in set(i['key'] for i in items):
    maj[key]=Counter(i['q'] for i in items if i['key']==key and i['conf']>0.08).most_common(1)[0][0]
tiles=[]
for it in items:
    q=it['q'] if it['conf']>0.08 else maj[it['key']]
    fin=(q+3)%4
    it['fin']=fin
    r,c=rc(it['fac'],it['k'])
    t=cell(F if it['side']=='f' else B,r,c)
    t=np.rot90(t,fin).copy()
    cv2.imwrite(f"{R}/pawns/{it['fac']}{it['k']:02d}_{it['side']}.png",cv2.resize(rounded(t,26),(160,160),interpolation=cv2.INTER_AREA))
print(Counter(i['fin'] for i in items))
print([(i['fac'],i['k'],i['side'],i['fin']) for i in items if i['fin']!=3])
