# Costruisce dati JSON e immagini per Magic Realm digitale a partire dal modulo TTS.
import json, os, re, sys
from PIL import Image
from tts import *
import tiles_data
OUT='/home/claude/magic-realm'
A=OUT+'/assets'; DD=OUT+'/data'
def salva(im, path, size=None, q=86):
    os.makedirs(os.path.dirname(path),exist_ok=True)
    if size: im=im.resize(size, Image.LANCZOS)
    if im.mode not in ('RGB','RGBA'): im=im.convert('RGBA')
    im.save(path,'WEBP',quality=q,method=5)
def apri(url):
    return Image.open(loc(url)).convert('RGBA')

# ---------------- tessere
NOMI_T={'Lost Woods':'Boschi Perduti','Old Woods':'Boschi Antichi','Dark Woods':'Boschi Oscuri','Deep Woods':'Boschi Profondi',
'High Pass':'Passo Alto','Borderland':'Terre di Confine','Caves':'Grotte','Cavern':'Caverna','Ivy Hills':"Colli dell'Edera",
'Fern Hills':'Colli delle Felci','Holly Hills':"Colli dell'Agrifoglio",'Grassy Hills':'Colli Erbosi','Jolly Hills':'Colli Allegri',
'Cliff':'Rupe','Mountain':'Montagna','Ledges':'Cenge','Crag':'Picco','Wasted Ruins':'Rovine Desolate','Ruins':'Rovine',
'Sundry Ruins':'Rovine Sparse','Grim Ruins':'Rovine Tetre','Evil Valley':'Valle Malvagia','Bad Valley':'Valle Cattiva',
'Awful Valley':'Valle Orrenda','Curst Valley':'Valle Maledetta','Dark Valley':'Valle Oscura','Nut Woods':'Bosco dei Noci',
'Maple Woods':'Bosco degli Aceri','Pine Woods':'Bosco dei Pini','Linden Woods':'Bosco dei Tigli','Oak Woods':'Bosco delle Querce',
'Falls':'Cascate','Steep Ruins':'Rovine Scoscese','Lake Woods':'Boschi del Lago','Grotto':'Grotta','Vale River':'Fiume della Valle',
'Rapid River':'Fiume Rapido','Sparkle River':'Fiume Scintillante','Trout River':'Fiume delle Trote','Utter River':'Fiume Estremo'}
SIGLE={}
tiles=[o for o,p in walk() if p and p[-1]=='Tiles']+[o for o,p in walk() if p and p[-1]=='River Tiles']
tess=[]
usate=set()
for i,o in enumerate(tiles):
    t=tiles_data.T[i]
    nome=NOMI_T[t['name']]
    # sigla: iniziali delle parole significative
    parole=[w for w in re.split(r"[ ']",nome) if w and w[0].isupper()]
    sig=''.join(w[0] for w in parole)
    if len(sig)<2: sig=nome[:2].upper()
    k=2
    while sig in usate:
        sig=(''.join(w[:k] for w in parole))[:3].upper() if len(parole)>0 else nome[:k+1].upper(); k+=1
    usate.add(sig)
    im=apri(o['CustomImage']['ImageURL'])
    # maschera esagonale pulita
    from PIL import ImageDraw
    import math
    mk=Image.new('L',im.size,0); d=ImageDraw.Draw(mk)
    pts=[(395+395*math.cos(math.radians(60*k2)),395+395*math.sin(math.radians(60*k2))) for k2 in range(6)]
    d.polygon(pts,fill=255)
    im.putalpha(mk)
    fid='t%02d'%i
    salva(im, A+'/tessere/%s.webp'%fid, q=88)
    tess.append(dict(id=fid,nome=nome,nome_en=t['name'],sigla=sig,cat=t['cat'],
        cl={str(n):[x,y,kd] for n,(x,y,kd) in t['cl'].items()}, strade=t['r'], nascosti=t['h'], segreti=t['s'], fiume=t['w']))
json.dump(tess,open(DD+'/tessere.json','w'),ensure_ascii=False,indent=1)
print('tessere',len(tess),[t['sigla'] for t in tess])

# ---------------- segnalini mappa
chits=[(p[-1],o) for o,p in walk() if p and (p[-1].endswith('Chits')) and o['Name']=='Custom_Tile']
NOMI_AV={'Bones':'Ossa','Dank':'Muffa','Smoke':'Fumo','Ruins':'Rovine','Stink':'Fetore'}
NOMI_SU={'Slither':'Fruscio','Roar':'Ruggito','Patter':'Zampettio','Howl':'Ululato','Flutter':'Frullo'}
NOMI_SITI={'Lair':'Covo','Tomb':'Tomba','Den':'Tana','Shrine':'Santuario','Hoard':'Bottino','Altar':'Altare','Pit':'Fossa',
 'Vault':'Sotterraneo','Maze':'Labirinto','Pool':'Stagno','Garden':'Giardino','Tower':'Torre','Cairns':'Tumuli','Statue':'Statua',
 'Temple':'Tempio','Spire':'Guglia'}
NOMI_PERD={'Castle':'Castello Perduto','City':'Città Perduta','Palace':'Palazzo Perduto','Fortress':'Fortezza Perduta'}
ident={0:('perduto','Castle',1),1:('perduto','City',3),78:('perduto','Palace',2),79:('perduto','Fortress',4)}
cat_seq={'C':['Bones','Dank','Smoke','Ruins','Stink'],'V':['Smoke','Stink','Ruins','Bones','Dank'],'W':['Dank','Ruins','Smoke','Bones','Stink'],
 'M':['Dank','Bones','Ruins','Stink','Smoke'],'H':['Dank','Ruins','Stink','Bones','Smoke'],'S':['Bones','Dank','Ruins','Stink','Smoke'],
 'F':['Stink','Bones','Dank','Ruins','Smoke'],'R':['Stink','Dank','Bones','Ruins','Smoke']}
start={'C':2,'V':7,'W':12,'M':17,'H':22,'S':27,'F':32,'R':37}
for c,s0 in start.items():
    for j,n in enumerate(cat_seq[c]): ident[s0+j]=('avviso',n,c)
siti=[('Lair',3),('Tomb',4),('Den',2),('Shrine',4),('Hoard',6),('Altar',1),('Pit',1),('Vault',3),('Maze',3),('Pool',6),('Garden',1),('Tower',5),('Cairns',5),('Statue',2),('Temple',5),('Spire',6)]
for j,(n,c) in enumerate(siti): ident[42+j]=('sito',n,c)
suoni=[('Slither',3),('Slither',6),('Slither',1),('Slither',5),('Roar',6),('Roar',5),('Roar',4),('Roar',3),('Patter',5),('Patter',4),('Patter',2),('Patter',1),('Howl',5),('Howl',4),('Howl',3),('Howl',2),('Flutter',6),('Flutter',4),('Flutter',2),('Flutter',1)]
for j,(n,c) in enumerate(suoni): ident[58+j]=('suono',n,c)
segn=[]
DWELL={('V','Stink'):'locanda',('V','Smoke'):'casa',('V','Dank'):'cappella',('V','Ruins'):'corpo_guardia',('V','Bones'):'borgo',
 ('H','Stink'):'casolare',('H','Smoke'):'insediamento',('H','Dank'):'capanna',('H','Ruins'):'fantasmi',('H','Bones'):'fantasmi',
 ('W','Smoke'):'fuoco_piccolo',('W','Stink'):'fuoco_grande',('S','Smoke'):'campo_piccolo',('S','Stink'):'campo_grande'}
retro_rosso=None; retri={}
for i,(pp,o) in enumerate(chits):
    tipo,n,c=ident[i]
    if tipo=='avviso':
        cid='%s_%s'%(n.lower(),c.lower()); nome='%s %s'%(NOMI_AV[n],c)
        extra=dict(nome_base=n,lettera=c,abitazione=DWELL.get((c,n)))
    elif tipo=='sito':
        cid='sito_'+n.lower(); nome='%s %d'%(NOMI_SITI[n],c); extra=dict(nome_base=n,radura=c)
    elif tipo=='suono':
        cid='%s_%d'%(n.lower(),c); nome='%s %d'%(NOMI_SU[n],c); extra=dict(nome_base=n,radura=c)
    else:
        cid='perduto_'+n.lower(); nome=NOMI_PERD[n]; extra=dict(nome_base=n,radura=c)
    a=apri(o['CustomImage']['ImageURL']); salva(a,A+'/segnalini/%s.webp'%cid,(160,160))
    b=o['CustomImage'].get('ImageSecondaryURL')
    if b:
        key=('giallo_'+c.lower()) if tipo=='avviso' else 'rosso'
        if key not in retri:
            retri[key]=1; salva(apri(b),A+'/segnalini/retro_%s.webp'%key,(160,160))
        extra['retro']='retro_'+key
    segn.append(dict(id=cid,tipo=tipo,nome=nome,**extra))
json.dump(segn,open(DD+'/segnalini.json','w'),ensure_ascii=False,indent=1)
print('segnalini',len(segn))

# ---------------- mostri
MON=json.load(open('mostri_def.json'))
mapn=MON['_mappa']
inst=[]; cont={}
for o in D['ObjectStates']:
    n=o.get('Nickname','')
    if o['Name']!='Custom_Tile' or not n: continue
    key=None
    for pat,k in mapn:
        if re.fullmatch(pat,n): key=k; break
    if not key: continue
    url=o['CustomImage']['ImageURL']
    if key in ('lupo','ratto'):
        if key not in cont: cont[key]={}
        if url not in cont[key]: cont[key][url]=len(cont[key])
        key=key+('_a' if cont[key][url]==0 else '_b')
    a=apri(url); b=o['CustomImage'].get('ImageSecondaryURL')
    sz=a.size[0]
    px=int(sz*0.62)
    imgid=key+'_%s'%re.sub(r'[^A-Za-z0-9]','',url)[-6:]
    if not os.path.exists(A+'/mostri/%s_a.webp'%imgid):
        salva(a,A+'/mostri/%s_a.webp'%imgid,(px,px))
        if b: salva(apri(b),A+'/mostri/%s_b.webp'%imgid,(px,px))
    inst.append(dict(tipo=key,img=imgid))
from collections import Counter
print('mostri istanze',len(inst),Counter(x['tipo'] for x in inst))
# raggruppa immagini per tipo
img_tipo={}
for x in inst: img_tipo.setdefault(x['tipo'],[]).append(x['img'])
MON['immagini']=img_tipo
del MON['_mappa']
json.dump(MON,open(DD+'/mostri.json','w'),ensure_ascii=False,indent=1)

# ---------------- abitazioni, armi, armature
AB={'Inn':'locanda','House':'casa','Chapel':'cappella','Guard':'corpo_guardia','Hamlet':'borgo','Cottage':'casolare','Settlement':'insediamento',
 'Hut':'capanna','Small Campfire':'fuoco_piccolo','Large Campfire':'fuoco_grande','Small Camp':'campo_piccolo','Large Camp':'campo_grande'}
for o in D['ObjectStates']:
    n=o.get('Nickname','')
    if o['Name']=='Custom_Tile' and n in AB:
        salva(apri(o['CustomImage']['ImageURL']),A+'/abitazioni/%s.webp'%AB[n],(200,200))
ARMI={'Axe':'ascia','Mace':'mazza','Short Sword':'spada_corta','Staff':'bastone','Thrusting Sword':'stocco','Medium Bow':'arco_medio',
 'Light Bow':'arco_leggero','Spear':'lancia','Great Sword':'spadone','Great Axe':'ascia_grande','Morning Star':'mazza_ferrata',
 'Crossbow (missile)':'balestra','Broadsword':'spada_larga','Bane Sword':'spada_funesta','Golden Axe':'ascia_dorata',
 'Helmet':'elmo','Breastplate':'corazza','Shield':'scudo','Suit of Armor':'armatura','Tremendous Suit of Armor':'armatura_t'}
fatti=set()
for o in D['ObjectStates']:
    n=o.get('Nickname','')
    if o['Name']=='Custom_Tile' and n in ARMI and ARMI[n] not in fatti:
        fatti.add(ARMI[n])
        salva(apri(o['CustomImage']['ImageURL']),A+'/oggetti/%s_a.webp'%ARMI[n],(170,170))
        b=o['CustomImage'].get('ImageSecondaryURL')
        if b: salva(apri(b),A+'/oggetti/%s_b.webp'%ARMI[n],(170,170))
print('oggetti',sorted(fatti))

# ---------------- personaggi (pedina, segnalino attenzione, scheda)
bags=[o for o in D['ObjectStates'] if o['Name']=='Bag' and (o.get('Description') or '').endswith('chits and counters.')]
for b in bags:
    nm=b['Nickname']; cid=re.sub(r'[^a-z]','_',nm.lower())
    objs=b['ContainedObjects']
    big=[x for x in objs if Image.open(loc(x['CustomImage']['ImageURL'])).size[0]>300]
    att=[x for x in objs if abs(x['Transform']['scaleX']-0.3474)<0.01]
    if big:
        x=big[0]; salva(apri(x['CustomImage']['ImageURL']),A+'/personaggi/%s_pedina.webp'%cid,(220,220))
        salva(apri(x['CustomImage']['ImageSecondaryURL']),A+'/personaggi/%s_nascosto.webp'%cid,(220,220))
    if att:
        salva(apri(att[0]['CustomImage']['ImageURL']),A+'/personaggi/%s_attenzione.webp'%cid,(120,120))
# schede personaggio (simbolo ritagliato)
for o in D['ObjectStates']:
    if o['Name']=='Custom_Tile' and not o.get('Nickname'):
        f=loc(o['CustomImage']['ImageURL']); im=Image.open(f)
        if im.size[1]>1500:
            pass
print('ok')
