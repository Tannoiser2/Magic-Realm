import json,random,time
T=json.load(open('/home/claude/magic-realm/data/tessere.json'))
DIR=[(0,-1),(1,-1),(1,0),(0,1),(-1,1),(-1,0)]
B=[]
for t in T:
    b=[['',''] for _ in range(6)]
    for lst,k in (('strade','r'),('fiume','w')):
        for s in t[lst]:
            p=s.split('-')
            for j in range(2):
                if p[j].startswith('e'): b[int(p[j][1:])]=[k,p[1-j]]
    B.append(b)
def bordo(t,rot,w): return B[t][(w-rot)%6][0]
def prova(rng,rilassato=False):
    cel={}
    def comb(t,c,rot):
        nv=coll=0
        for w in range(6):
            n=(c[0]+DIR[w][0],c[1]+DIR[w][1])
            if n not in cel: continue
            nv+=1
            tt,rr=cel[n]
            if bordo(t,rot,w)!=bordo(tt,rr,(w+3)%6): return (False,nv,coll)
            if bordo(t,rot,w): coll+=1
        return (True,nv,coll)
    r0=rng.randrange(6); cel[(0,0)]=(31,r0)
    ac=(0,0); aw=[w for w in range(6) if bordo(31,r0,w)=='w'][0]
    fi=[32,33,35,36,37,38,39]; rng.shuffle(fi); fi.append(34)
    while fi:
        c=(ac[0]+DIR[aw][0],ac[1]+DIR[aw][1])
        if c in cel: return None
        ok=False
        for i,t in enumerate(fi):
            if t==34 and len(fi)>1: continue
            opz=[]
            for rot in range(6):
                if bordo(t,rot,(aw+3)%6)!='w': continue
                if not comb(t,c,rot)[0]: continue
                alt=[w for w in range(6) if w!=(aw+3)%6 and bordo(t,rot,w)=='w']
                alt=alt[0] if alt else -1
                if alt>=0 and (c[0]+DIR[alt][0],c[1]+DIR[alt][1]) in cel: continue
                opz.append((rot,alt))
            if not opz: continue
            rot,alt=rng.choice(opz); cel[c]=(t,rot); fi.pop(i); ac=c; aw=alt; ok=True; break
        if not ok: return None
    resto=[t for t in range(40) if t not in [v[0] for v in cel.values()]]
    rng.shuffle(resto)
    while resto:
        placed=False
        celle=set()
        for (q,r) in cel:
            for d in DIR:
                n=(q+d[0],r+d[1])
                if n not in cel: celle.add(n)
        for i,t in enumerate(resto):
            cand=[]
            for c in celle:
                for rot in range(6):
                    v,nv,coll=comb(t,c,rot)
                    if v and nv>=(1 if rilassato or len(cel)<12 else 2) and coll>=1: cand.append((c,rot,nv*nv+coll))
            if not cand: continue
            c,rot,_=rng.choices(cand,weights=[x[2] for x in cand])[0]
            cel[c]=(t,rot); resto.pop(i); placed=True; break
        if not placed: return None
    return cel
for ril in (False,True):
    succ=0; t0=time.time()
    for s in range(200):
        rng=random.Random(s)
        if prova(rng,ril): succ+=1
    print('rilassato',ril,'successi',succ,'/200',time.time()-t0)

def grafo(cel):
    V={}
    def arco(a,b):
        V.setdefault(a,set()).add(b); V.setdefault(b,set()).add(a)
    pos={v[0]:(c,v[1]) for c,v in cel.items()}
    for t,(c,rot) in pos.items():
        d=T[t]
        for n in d['cl']: V.setdefault('%d:%s'%(t,n),set())
        for lst in ('strade','nascosti','segreti','fiume'):
            for s in d[lst]:
                p=s.split('-')
                if p[0].startswith('e') or p[1].startswith('e'): continue
                arco('%d:%s'%(t,p[0]),'%d:%s'%(t,p[1]))
        for w in range(3):
            n=(c[0]+DIR[w][0],c[1]+DIR[w][1])
            if n not in cel: continue
            t2,r2=cel[n]
            b1=B[t][(w-rot)%6]; b2=B[t2][((w+3)%6-r2)%6]
            if b1[0] and b2[0]: arco('%d:%s'%(t,b1[1]),'%d:%s'%(t2,b2[1]))
    return V
bad={}
for s in range(50):
    cel=prova(random.Random(s))
    V=grafo(cel)
    start=[k for k in V if T[int(k.split(':')[0])]['cl'][k.split(':')[1]][2]=='A']
    vis=set(start); q=list(start)
    while q:
        x=q.pop()
        for y in V[x]:
            if y not in vis: vis.add(y); q.append(y)
    tiles=set(int(k.split(':')[0]) for k in vis)
    for t in range(40):
        if t not in tiles: bad[t]=bad.get(t,0)+1
print('tessere scollegate',{T[t]['nome']:n for t,n in bad.items()})
