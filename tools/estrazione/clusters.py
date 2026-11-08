from PIL import Image
import numpy as np
from scipy import ndimage
import json
res={}
for i in range(40):
    a=np.array(Image.open('tiles/t%02da.png'%i).convert('RGB')).astype(int)
    r,g,b=a[...,0],a[...,1],a[...,2]
    m=(r>200)&(g>170)&(b<90)&(r-b>130)
    m=ndimage.binary_dilation(m,iterations=6)
    lab,n=ndimage.label(m)
    cs=[]
    for k in range(1,n+1):
        ys,xs=np.nonzero(lab==k)
        if len(xs)<250: continue
        w=xs.max()-xs.min(); h=ys.max()-ys.min()
        if w>110 or h>90: continue
        cs.append((int(xs.mean()),int(ys.mean()),len(xs)))
    res[i]=cs
    print(i,len(cs),cs)
json.dump(res,open('clusters.json','w'))
