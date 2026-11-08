import sys,re,json
sys.path.insert(0,'.')
from tts import *
L=[l.strip() for l in open('/home/claude/testi/rules_raw.txt').read().split('\n')[14830:16000] if l.strip()]
txt='|'.join(L)
GR=['Aborigines','Bandits','Conjurors','Coven','Cultists','Dwarves','Elves','Enchanters','Hunters','Mages','Mercenaries','Pagans','Peasants','Summoners','Zealots','Bashkars','Company','Guard','Lancers','Order','Patrol','Rogues','Soldiers','Woodfolk']
TIPI=['S. Swordsman','G. Swordsman','G. Axeman','Swordsman','Axeman','Archer','Assassin','Pikeman','Crossbowman','Spearman','Knight','Raider','Peasant','Dwarf','Caster']
pos={}
for g in GR:
    m=re.search(r'\|'+g+r'\|',txt); pos[g]=m.start() if m else None
ordin=sorted([g for g in GR if pos[g] is not None],key=lambda g:pos[g])
blocchi={}
for i,g in enumerate(ordin):
    end=pos[ordin[i+1]] if i+1<len(ordin) else len(txt)
    b=txt[pos[g]:end].split('Notes:')[0]
    tipi=[]
    for tok in b.split('|'):
        t=re.sub(r'\d$','',tok).strip()
        if t in TIPI: tipi.append(t)
    blocchi[g]=tipi
for g in GR: print(g, blocchi.get(g))
json.dump(blocchi,open('/home/claude/lavoro/s5/tipi.json','w'))
