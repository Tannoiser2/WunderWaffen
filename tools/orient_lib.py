import cv2,numpy as np
colb=[-12,227,466,707,949,1187,1427,1668,1907]; rowb=[-9,231,470,710,949,1188,1426,1666,1904,2147,2398,2638]
F=cv2.imread('scan/pedine/p-000.jpg'); B=cv2.imread('scan/pedine/p-001.jpg')
SHEETCOL={'ger':6,'ussr':2,'usa':4,'uk':0}
def cell(im,r,c,size=212):
    cx=(colb[c]+colb[c+1])/2; cy=(rowb[r]+rowb[r+1])/2
    x0=int(cx-size/2); y0=int(cy-size/2)
    pad=cv2.copyMakeBorder(im,40,40,40,40,cv2.BORDER_REPLICATE)
    return pad[y0+40:y0+40+size,x0+40:x0+40+size]
def rc(fac,k): return k%9, SHEETCOL[fac]+k//9
