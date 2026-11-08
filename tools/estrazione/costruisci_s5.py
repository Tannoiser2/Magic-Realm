import sys,re,json
sys.path.insert(0,'.')
from tts import *
from PIL import Image
A='/home/claude/magic-realm/assets/nativi/'
tipi=json.load(open('/home/claude/lavoro/s5/tipi.json'))
tipi['Rogues']=['Assassin','G. Axeman','G. Axeman','S. Swordsman','S. Swordsman','Archer','Archer','Assassin','Swordsman','Swordsman']
tipi['Soldiers']=['G. Swordsman','Pikeman','Pikeman','Pikeman','Crossbowman','Crossbowman']
tipi['Woodfolk']=['Archer']*4
SING={'Aborigine':'Aborigines','Bandit':'Bandits','Conjuror':'Conjurors','Coven':'Coven','Cultist':'Cultists','Dwarf':'Dwarves','Elf':'Elves','Enchanter':'Enchanters',
 'Hunter':'Hunters','Mage':'Mages','Mercenary':'Mercenaries','Pagan':'Pagans','Peasant':'Peasants','Summoner':'Summoners','Zealot':'Zealots','Bashkar':'Bashkars',
 'Company':'Company','Guard':'Guard','Lancer':'Lancers','Order':'Order','Patrol':'Patrol','Rogue':'Rogues','Soldier':'Soldiers','Woodfolk':'Woodfolk','Witch':'Coven','Coven Witch':'Coven','Bandits':'Bandits','Dwarves':'Dwarves','Elves':'Elves'}
# statistiche per tipo: (luce attacco, luce mossa, buio attacco, buio mossa, missile)
ST={'Archer':('',2,'L1**',4,True),'Assassin':('M3*',4,'L4*',2,False),'Axeman':('M5*',3,'M3*',4,False),'G. Axeman':('H5*',4,'T3*',5,False),
 'Swordsman':('M3*',5,'L3*',4,False),'S. Swordsman':('M4*',3,'L4*',3,False),'G. Swordsman':('T4*',6,'H5*',5,False),'Pikeman':('H6*',4,'M4*',5,False),
 'Crossbowman':('',5,'H1',4,True),'Spearman':('H5*',3,'M3*',4,False),'Knight':('H6*',4,'T4*',6,False),'Raider':('L4*',2,'M4*',3,False),
 'Peasant':('M4',5,'L3',3,False),'Dwarf':('T6*',5,'T6*',4,False),'Caster':('',4,'M4',4,False)}
CASTER={'Pagans':('',4,'M5',3),'Summoners':('M5',2,'M4',2),'Zealots':('M3',5,'M5',4),'Conjurors':('',5,'M4',4),'Coven':('',1,'',1),'Cultists':('',5,'M4',4),'Enchanters':('',4,'M4',3),'Mages':('',5,'M3',4),'Elves':('',2,'L1**',4)}
PESI={'light':'L','medium':'M','heavy':'H','tremendous':'T'}
gr={}
for o in D['ObjectStates']:
    if o['Name']!='Custom_Tile': continue
    n=(o.get('Nickname') or '').strip()
    m=re.match(r'^([A-Za-z ]+?) (HQ|\d+), (light|medium|heavy|tremendous)(, armored)?$',n)
    if not m: continue
    g=SING.get(m.group(1))
    if not g: print('??',n); continue
    d=o.get('Description','')
    noto=int(re.search(r'(\d+) Notoriety',d).group(1)) if 'Notoriety' in d else 0
    oro=int(re.search(r'(\d+) Gold',d).group(1)) if 'Gold' in d else 0
    idx=0 if m.group(2)=='HQ' else int(m.group(2))
    ci=o['CustomImage']
    fa=loc(ci['ImageURL']); fb=loc(ci.get('ImageSecondaryURL',''))
    gid=g.lower().replace(' ','_')
    mid=f'{gid}_{"hq" if idx==0 else idx}'
    for f,lato in ((fa,'a'),(fb,'b')):
        if f:
            im=Image.open(f).convert('RGBA'); im.thumbnail((160,160)); im.save(A+f'{mid}_{lato}.webp',quality=85)
    gr.setdefault(g,[]).append({'id':mid,'i':idx,'peso':PESI[m.group(3)],'armato':bool(m.group(4)),'noto':noto,'oro':oro,'missile':'Missile' in d,
        'img':f'nativi/{mid}_a.webp','img_b':f'nativi/{mid}_b.webp' if fb else f'nativi/{mid}_a.webp'})
for g in gr:
    gr[g].sort(key=lambda x:x['i'])
    tt=tipi.get(g) or []
    for k,mb in enumerate(gr[g]):
        t=tt[k] if k<len(tt) else (tt[-1] if tt else 'Swordsman')
        s=ST[t]
        if t=='Caster' or g=='Elves':
            c=CASTER[g]; s=(c[0],c[1],c[2],c[3],g=='Elves')
        mb['tipo']=t; mb['luce']=[s[0],s[1]]; mb['buio']=[s[2],s[3]]; mb['missile']=mb['missile'] or s[4]
        mb['caster']=t=='Caster'
    print(g,len(gr[g]),[m['tipo'] for m in gr[g]])
json.dump(gr,open('/home/claude/lavoro/s5/gruppi.json','w'),indent=0)
