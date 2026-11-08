import sys, math, numpy as np
from PIL import Image
from scipy import ndimage
def analyze(i, cl, rad=48, show=False):
    a=np.array(Image.open('tiles/t%02da.png'%i).convert('RGBA')).astype(int)
    r,g,b,al=a[...,0],a[...,1],a[...,2],a[...,3]
    road=(r>150)&(g>115)&(b<150)&(r-b>35)&(r-g<55)
    dark=(r<70)&(g<70)&(b<70)&(abs(r-g)<20)&(abs(g-b)<25)
    water=(b>r+25)&(b>140)
    yy,xx=np.mgrid[0:791,0:791]
    # hex mask
    inside=np.ones((791,791),bool)
    for e in range(6):
        ang=math.radians(90-60*e); nx,ny=math.cos(ang),-math.sin(ang)
        inside&=((xx-395)*nx+(yy-395)*ny)<340
    near_edge={}
    for e in range(6):
        ang=math.radians(90-60*e); nx,ny=math.cos(ang),-math.sin(ang)
        d=(xx-395)*nx+(yy-395)*ny
        near_edge['e%d'%e]=(d>318)&(d<340)&inside
    disks={}
    for n,(x,y) in cl.items():
        disks[str(n)]=(xx-x)**2+(yy-y)**2<rad*rad
    out={}
    for nm,m in (('road',road),('dark',dark),('water',water)):
        m=m&inside
        m=ndimage.binary_opening(m,iterations=2)
        for d in disks.values(): m&=~d
        lab,n=ndimage.label(m)
        res=[]
        for k in range(1,n+1):
            c=lab==k
            if c.sum()<600: continue
            cd=ndimage.binary_dilation(c,iterations=4)
            t=[n2 for n2,d in disks.items() if (cd&d).any()]
            t+=[e for e,em in near_edge.items() if (c&em).sum()>60]
            if len(t)>=2 or True:
                res.append((int(c.sum()),t))
        out[nm]=res
    return out
if __name__=='__main__':
    import json
    i=int(sys.argv[1]); cl=json.loads(sys.argv[2])
    for k,v in analyze(i,cl).items():
        print(k, [x for x in v if len(x[1])>=1])
