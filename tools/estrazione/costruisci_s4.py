import json,re,sys
from PIL import Image
sys.path.insert(0,'.')
from tesori_src import T,TWT
from incantesimi_src import S
W='/home/claude/lavoro/s4/'; A='/home/claude/magic-realm/assets/'
def slug(x): return re.sub(r'[^a-z0-9]+','_',x.lower()).strip('_')
def grande(f):
    im=Image.open(W+f'/t_{f}.png').convert('RGB'); w,h=im.size
    r,g,b=im.getpixel((3,h//2)); return r>90 and g<50 and b<60
out={}; usati={}
for f,en,it,peso,fama,cond,noto,oro,eff in T:
    k='t_'+slug(en); n=usati.get(k,0); usati[k]=n+1
    if n: k+=f'_{n+1}'
    im=Image.open(W+f't_{f}.png').convert('RGB'); im=im.resize((240,int(240*im.height/im.width)),Image.LANCZOS)
    im.save(A+f'tesori/{k}.webp',quality=82)
    out[k]={"nome":it,"nome_en":en,"taglia":"G" if f[0]=='L' else "P","grande":grande(f),"peso":peso,"fama":fama,
       "fama_cond":list(cond) if cond else None,"noto":noto,"oro":oro,"eff":eff,"img":f"tesori/{k}.webp"}
for f,en,it,tipo,col in TWT:
    k='w_'+slug(en)
    im=Image.open(W+f't_{f}.png').convert('RGB'); im=im.resize((240,int(240*im.height/im.width)),Image.LANCZOS)
    im.save(A+f'tesori/{k}.webp',quality=82)
    out[k]={"nome":it,"nome_en":en,"taglia":"W","twt":tipo,"colore":col,"grande":False,"peso":"T" if tipo=="forziere" else "-",
       "fama":0,"fama_cond":None,"noto":0,"oro":0,"eff":{},"img":f"tesori/{k}.webp"}
json.dump(out,open('/home/claude/magic-realm/data/tesori.json','w'),ensure_ascii=False,indent=0)
# incantesimi
ocr=json.load(open(W+'ocr_sp.json'))
for c in ocr:
    if (c['t'],c['i']) in [('III',7),('V',8),('VI',6),('VI',9),('I',6),('VIII',6)]: c['u']=1
def nn(x): return re.sub(r'[^a-z]','',x.lower())
inc={}
for en,it,tipo,col,dur,testo,eff in S:
    k='i_'+slug(en)
    img=''
    key=nn(en)[:9]
    FORZA={'Persuade':('III',7),'Reanimate':('V',8),'Melt into Mist':('VI',6),'Transform':('VI',9),'Redirect':('I',6),'Poison':('VIII',6)}
    if en in FORZA:
        t2,i2=FORZA[en]
        for c in ocr:
            if c['t']==t2 and c['i']==i2: c['u']=1
        img=f'sp_{t2}_{i2:02d}.png'
    for c in ([] if img else ocr):
        if c['t']==tipo and key in nn(c['ocr']) and not c.get('u'):
            c['u']=1; img=f'sp_{tipo}_{c["i"]:02d}.png'; break
    if not img:
        for c in ocr:
            if c['t']==tipo and nn(en.split()[-1])[:6] in nn(c['ocr']) and not c.get('u'):
                c['u']=1; img=f'sp_{tipo}_{c["i"]:02d}.png'; break
    if img:
        im=Image.open(W+img).convert('RGB'); im=im.resize((240,int(240*im.height/im.width)),Image.LANCZOS)
        im.save(A+f'incantesimi/{k}.webp',quality=82); img=f'incantesimi/{k}.webp'
    else: print('senza immagine',en)
    inc[k]={"nome":it,"nome_en":en,"tipo":tipo,"colore":col,"durata":dur,"testo":testo,"eff":eff,"img":img}
json.dump(inc,open('/home/claude/magic-realm/data/incantesimi.json','w'),ensure_ascii=False,indent=0)
print(len(out),len(inc),sum(1 for v in out.values() if v['grande']),'grandi', [c['i'] for c in ocr if not c.get('u')], [(c['t'],c['ocr'][:40]) for c in ocr if not c.get('u')])
