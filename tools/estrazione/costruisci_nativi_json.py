import json,re
gr=json.load(open('/home/claude/lavoro/s5/gruppi.json'))
rel=json.load(open('/home/claude/lavoro/s5/rel.json'))
IT={'Aborigines':'Aborigeni','Bandits':'Banditi','Conjurors':'Evocatori','Coven':'Congrega','Cultists':'Cultisti','Dwarves':'Nani','Elves':'Elfi','Enchanters':'Incantatori',
 'Hunters':'Cacciatori','Mages':'Magi','Mercenaries':'Mercenari','Pagans':'Pagani','Peasants':'Contadini','Summoners':'Convocatori','Zealots':'Zeloti','Bashkars':'Bashkar',
 'Company':'Compagnia','Guard':'Guardia','Lancers':'Lancieri','Order':'Ordine','Patrol':'Pattuglia','Rogues':'Furfanti','Soldiers':'Soldati','Woodfolk':'Gente dei boschi'}
TIPI_IT={'Archer':'Arciere','Assassin':'Assassino','Axeman':'Guerriero con ascia','G. Axeman':'Grande ascia','Swordsman':'Spadaccino','S. Swordsman':'Spada corta',
 'G. Swordsman':'Spadone','Pikeman':'Picchiere','Crossbowman':'Balestriere','Spearman':'Lanciere','Knight':'Cavaliere','Raider':'Predone','Peasant':'Contadino','Dwarf':'Nano','Caster':'Incantatore'}
LUNG={'Archer':14,'Crossbowman':12,'G. Swordsman':8,'G. Axeman':5,'Pikeman':10,'Spearman':10,'Swordsman':4,'S. Swordsman':3,'Assassin':3,'Axeman':2,'Knight':6,'Raider':3,'Peasant':1,'Dwarf':5,'Caster':1}
# tabella dei clan: riga del tiro dei nativi, abitazioni o guarnigione, tesori, incantesimi, oggetti
D_={'cappella':'Chapel','corpo_guardia':'Guard house','borgo':'Hamlet','campo_grande':'L. Camp','casolare':'Cottage','insediamento':'Settlement','capanna':'Hut','campo_piccolo':'S. Camp','fuoco_piccolo':'S. Fire','fuoco_grande':'L. Fire','casa':'House','locanda':'Inn'}
C={
 'Zealots':(1,None,['cappella','corpo_guardia','borgo','campo_grande'],['I'],['armatura']),
 'Summoners':(1,'casolare',[],['III','III','VII','VII'],[]),
 'Mercenaries':(1,None,['casolare','insediamento','capanna'],[],['spadone','balestra','mazza_ferrata']),
 'Peasants':(2,'borgo',[],[],[]),
 'Aborigines':(2,None,['campo_grande','campo_piccolo','fuoco_piccolo'],[],['arco_leggero','ascia','ascia']),
 'Coven':(2,None,['casolare','borgo','capanna','fuoco_grande'],['V'],['bastone','bastone']),
 'Patrol':(3,None,['cappella','corpo_guardia','casa','locanda'],[],['elmo','corazza','scudo']),
 'Bashkars':(3,None,['campo_piccolo','fuoco_piccolo','fuoco_grande'],[],[]),
 'Mages':(3,'insediamento',[],['IV','IV','IV'],['elmo','elmo','corazza','corazza','scudo','scudo']),
 'Soldiers':(4,'casa',[],[],['spada_corta','spada_corta','stocco','stocco','spada_corta','stocco','spada_corta','scudo','scudo','elmo','elmo','elmo']),
 'Pagans':(4,'capanna',[],['II','II'],['bastone','bastone']),
 'Hunters':(4,None,['locanda','campo_grande','fuoco_piccolo'],[],['ascia','arco_medio','lancia']),
 'Guard':(5,'corpo_guardia',[],[],['spada_larga','spada_larga','mazza','mazza','ascia','lancia','corazza','elmo']),
 'Woodfolk':(5,None,['casa','capanna','fuoco_piccolo'],[],['arco_medio','arco_leggero','arco_leggero']),
 'Company':(5,None,['locanda','campo_grande','fuoco_grande'],[],['elmo','corazza','scudo']),
 'Conjurors':(5,None,['borgo','insediamento','campo_piccolo'],['VI'],['elmo','corazza']),
 'Order':(6,'cappella',[],[],['armatura','armatura','spadone','spadone','mazza_ferrata','ascia_grande','ascia_grande']),
 'Lancers':(6,None,['cappella','casolare','campo_piccolo','fuoco_grande'],[],['lancia','lancia','lancia','lancia']),
 'Rogues':(6,'locanda',[],[],[]),
 'Enchanters':(6,None,['corpo_guardia','casa','insediamento'],['VII'],['corazza','scudo']),
}
ROV={'Bandits':([2,3],'Castle'),'Cultists':([1,2],'Fortress'),'Dwarves':([5,6],'City'),'Elves':([3,4],'Palace')}
out={"gruppi":{},"relazioni":{}}
for g,mem in gr.items():
    gid=g.lower()
    e={"nome":IT[g],"nome_en":g,"membri":[]}
    if g in C:
        r,gar,ab,inc,ogg=C[g]; e.update({"riga":r,"guarnigione":gar,"abitazioni":ab,"inc":inc,"oggetti":ogg,"vagante":False})
    else:
        rr,lost=ROV[g]; e.update({"righe":rr,"perduto":lost,"inc":[],"oggetti":[],"vagante":True})
    for m in mem:
        lato=lambda x:[x[0],int(x[1])]
        e["membri"].append({"id":m["id"],"capo":m["i"]==0,"tipo":m["tipo"],"tipo_it":TIPI_IT[m["tipo"]],"peso":m["peso"],"armato":m["armato"],"noto":m["noto"],"oro":m["oro"],
            "luce":lato(m["luce"]),"buio":lato(m["buio"]),"missile":m["missile"],"lung":LUNG[m["tipo"]],"img":m["img"],"img_b":m["img_b"]})
    out["gruppi"][gid]=e
P=json.load(open('/home/claude/magic-realm/data/personaggi.json'))
VAL={'Ally':2,'Friendly':1,'Unfriendly':-1,'Enemy':-2}
for p in P:
    rr=rel.get(p['nome_en'],{}); d={}
    for k,l in rr.items():
        for x in l:
            x=re.sub(r'\s*Development/Combat Chits:','',x).strip()
            if x=='Guards': x='Guard'
            d[x.lower()]=VAL[k]
    out["relazioni"][p['id']]=d
json.dump(out,open('/home/claude/magic-realm/data/nativi.json','w'),ensure_ascii=False,indent=0)
print(len(out['gruppi']), out['relazioni']['amazzone'])
