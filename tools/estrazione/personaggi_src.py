import json,re
from PIL import Image
# chit: 'Move M3*' -> tipo M ; 'Fight' -> F ; magia 'II3*' -> G ; Berserk/Reflex/Duck speciali
RAW={
'amazzone':('Amazzone','Amazon','M','M',['Inn'],
 ['Move M3*','Move M4','Fight L4','Move M4','Fight M5','Fight M4*','Move M3*','Fight M3**','Fight H4**','Move M3*','Fight M4*','Fight M3**'],['spada_corta','elmo','corazza','scudo'],
 ['mira','resistenza']),
'barbaro':('Barbaro','Barbarian','H','H',['Inn'],
 ['Fight H5*','Move H6','Move H5*','Fight H6','Fight H4**','Move T6*','Fight H5*','Fight T5*','Move T5**','Fight T4**','Fight T4**','Move H4**'],['spadone','scudo','corazza'],
 ['furia','robusto']),
'bardo':('Bardo','Bard','L','L',['Inn'],
 ['Fight L4','Move L3*','Move L4','VII3*','Move L2**','Fight L3*','III3*','II4*','Fight L3*','III2*','II3*','VIII2**'],[],[]),
'berserker':('Berserker','Berserker','H','H',['Inn'],
 ['Move H5*','Move H6','Fight H4*','Move H4**','Move T6*','Fight H5','Move H4**','Fight T4**','Fight T6*','Berserk T4**','Fight T4**','Fight T5*'],['ascia_grande','elmo'],
 ['robusto','berserk']),
'cavaliere_nero':('Cavaliere Nero','Black Knight','M','M',['Inn'],
 ['Move M5','Move H5*','Fight H5*','Move M4*','Move H6','Fight H6','Fight M4*','Fight M4*','Fight M5','Move H4**','Fight H4**','Fight M3**'],['mazza','armatura','scudo'],
 ['mira']),
'capitano':('Capitano','Captain','M','M',['Inn','Guard','House'],
 ['Move M4*','Move M5','Fight H5*','Move M3**','Fight M3**','Fight M5','Move M4*','Fight M4*','Fight H5*','Move M4*','Fight H6','Fight M4*'],['spada_corta','elmo','corazza','scudo'],
 ['mira','reputazione']),
'druido':('Druido','Druid','L','L',['Inn','Hut'],
 ['Move L3*','Move L4','Fight L3*','Move L2**','Fight L2**','Fight L4','II3*','VIII4*','VIII3*','II2**','VIII2**','II3*'],[],['occultamento','pace_natura']),
'nano':('Nano','Dwarf','H','H',['Inn','Guard'],
 ['Move H6','Duck T3*','Fight H5*','Move T6*','Fight H6*','Fight H4**','Move H5*','Fight H4**','Fight T6*','Move T5**','Fight T5**','Fight T5**'],['ascia_grande','elmo'],
 ['gambe_corte','grotte']),
'elfo':('Elfo','Elf','L','L',['Inn','Cottage','Hut'],
 ['III3*','III4*','VII4*','III2*','III3*','VII3*','Move L2*','Move L3*','Fight L3*','Move M4','Fight M3*','Fight M4'],['arco_leggero'],['sfuggente','arciere']),
'gladiatore':('Gladiatore','Gladiator','H','H',['Inn','Hamlet','Settlement'],
 ['Move H6','Move H4*','Fight H5*','Move T5*','Reflex H3**','Fight H6','Fight H4**','Fight H5*','Move T4**','Move T4**','Fight H4**','Fight H5*'],['mazza_ferrata','armatura'],
 ['riflessi','robusto']),
'mago':('Mago','Magician','L','L',['Inn'],
 ['Move L3*','Move L4','Fight L3*','Move M4*','Fight L4','II3*','III3*','VII4**','VIII4*','IV3*','V4**','VI4*'],[],['strumenti_magici']),
'negromante':('Negromante','Necromancer','M','H',['Inn','Settlement'],
 ['V4*','Move M5','Fight M4*','V3*','V2**','VIII3**','VI5**','VI6*','VI6*','VI4*','VI4*','VI4*'],[],[]),
'paladino':('Paladino','Paladin','M','M',['Inn','Chapel','Hamlet'],
 ['Move M5','Move M4*','Fight M4*','I4*','Fight M5','Fight M3**','VII6*','Move M3**','Move H6','I2**','IV4*','Fight H6'],['mazza','elmo','corazza','scudo'],['compagno']),
'pellegrino':('Pellegrino','Pilgrim','M','M',['Inn','Chapel'],
 ['Move M4*','Move M5','Fight M3*','Move H5*','Fight M4','Fight M2**','Fight M3*','I6*','VII3*','Move H6','Fight H4*','I4*'],['bastone'],['protezione_celeste']),
'sensitiva':('Sensitiva','Psychic','M','M',['Inn','Hamlet','Settlement'],
 ['Move M5','Move M4*','Fight L4','Fight M5','IV4**','II4*','VII4*','II3*','Move M5','Fight M4*','VII2*','II2**'],['bastone'],['visione']),
'stregone':('Stregone','Sorcerer','M','M',['Inn'],
 ['Move M4*','Move M5','Fight L3*','IV4*','IV4*','IV4*','VI4*','VI5*','VI6*','IV3*','IV3*','IV5*'],[],[]),
'spadaccino':('Spadaccino','Swordsman','L','L',['Inn'],
 ['Move L3*','Move L4','Fight L3*','Move L2**','Move L3*','Fight L2**','Move M4*','Fight M3**','Fight M4*','Fight L2**','Fight L4','Fight M5'],['stocco'],['astuto']),
'pescatore':('Pescatore','Trawler','L','L',['Inn','Cottage','Hut'],
 ['Move L3*','Move L4','Fight L3*','Move L2**','Move M4*','Fight M3**','Move M3**','Fight M4*','Fight L3*','Fight M5','Fight M3**','Fight L4'],['stocco'],['navigatore','affondo']),
'viandante':('Viandante','Wanderer','M','M',['Inn','Cottage'],
 ['Move M4*','Move M5','Fight M4*','II3*','Move M3**','Fight M5','Fight M3**','Move M4*','Fight H5*','Fight M4*','Move M3**','Fight H6'],['spada_larga','elmo','corazza','scudo'],
 ['scalatore','uomo_frontiera']),
'cavaliere_bianco':('Cavaliere Bianco','White Knight','H','H',['Inn','Chapel'],
 ['Move H5*','Move H6','Fight H5*','Move H4**','Fight H4**','Fight H6','Fight H4**','Fight H5*','I5**','Move T6*','Fight T4**','Fight T5*'],['spadone','armatura'],['salute']),
'strega':('Strega','Witch','L','L',['Inn'],
 ['Move L3*','Move L4','Move M4*','II3*','V6*','VIII4*','Fight L3*','II3*','V5*','II2*','V4*','VIII2*'],[],[]),
're_stregone':('Re Stregone','Witch King','L','L',['Inn'],
 ['IV4*','V4*','VI4*','IV4*','V3*','VI3*','IV3*','V3*','VI3*','IV3*','V2*','VI2*'],[],[]),
'stregone_bianco':('Arcimago','Wizard','M','M',['Inn','House','Guard'],
 ['Move M5','Move M4*','Fight M3*','Move M5','Move M5','Fight M5','Fight L4','II4*','IV4*','II3*','III3','IV3*'],['bastone'],['esperienza']),
'ragazza_boschi':('Ragazza dei Boschi','Woods Girl','L','L',['Inn','House'],
 ['Move L3*','Move L4','Move L2**','VII6**','Fight L4','Move L2**','Fight L3*','Fight M5','Fight L4','Move L3*','Fight M4*','Fight L3*'],['arco_leggero'],['inseguitrice','arciere']),
}
ABIL={
'mira':('MIRA','Sottrae 1 da ogni dado quando tira sulla tabella dei Proiettili con un\'arma da tiro.'),
'resistenza':('RESISTENZA','Può registrare ed eseguire una fase di MOVIMENTO in più ogni giorno.'),
'furia':('FURIA','Nessun limite di sforzo in combattimento: alla fase di Fatica affatica tutti gli sforzi giocati meno uno. Agisce sempre per ultimo nei round di combattimento.'),
'robusto':('ROBUSTO','Può registrare ed eseguire una fase di RIPOSO in più ogni giorno.'),
'berserk':('BERSERK','Può giocare il segnalino Berserk (in un\'Allerta o come azione in combattimento): fino a mezzanotte la sua vulnerabilità diventa Tremenda.'),
'reputazione':('REPUTAZIONE','Ottiene una fase in più ogni giorno in cui si trova in un\'abitazione quando la esegue.'),
'occultamento':('OCCULTAMENTO','Tira un solo dado per nascondersi.'),
'pace_natura':('PACE CON LA NATURA','Quando termina il turno, i segnalini di Avviso e di Suono della sua tessera non evocano mostri.'),
'gambe_corte':('GAMBE CORTE','Usa solo le fasi Base (mai quelle di Luce). Quando riposa recupera un asterisco in più. Il segnalino Schivata in basso vale solo per la manovra "Abbassarsi".'),
'grotte':('CONOSCENZA DELLE GROTTE','In una radura di grotta tira un solo dado per nascondersi e per tutte le tabelle di ricerca.'),
'sfuggente':('SFUGGENTE','Può registrare ed eseguire una fase di NASCONDERSI in più ogni giorno.'),
'arciere':('ARCIERE','Tira un solo dado sulla tabella dei Proiettili quando attacca con arco o balestra.'),
'riflessi':('RIFLESSI','Può affaticare il segnalino Riflessi durante l\'azione di combattimento per allertare l\'arma attiva.'),
'strumenti_magici':('STRUMENTI MAGICI','Può registrare ed eseguire una fase di ALLERTA in più ogni giorno.'),
'compagno':('COMPAGNO','Fase in più se un altro personaggio lo segue.'),
'protezione_celeste':('PROTEZIONE CELESTE','Demoni, Demoni alati, Imp, Vampiro e Succube non possono bloccarlo né essergli assegnati.'),
'visione':('VISIONE','Può registrare ed eseguire una fase di RICERCA in più ogni giorno.'),
'astuto':('ASTUTO','Sceglie lui quando giocare il proprio turno durante il giorno.'),
'navigatore':('NAVIGATORE','Gli basta una sola fase di movimento per entrare in qualsiasi radura d\'acqua.'),
'affondo':('AFFONDO','Quando gioca un segnalino Combattimento nel cerchio "Affondo" la sua forza sale di un livello.'),
'scalatore':('SCALATORE','Gli basta una sola fase di movimento per salire su una radura di montagna.'),
'uomo_frontiera':('UOMO DI FRONTIERA','In una radura di montagna tira un solo dado per nascondersi e per tutte le tabelle di ricerca.'),
'salute':('SALUTE','Può registrare ed eseguire una fase di RIPOSO in più ogni giorno.'),
'esperienza':('ESPERIENZA','Conosce fin dall\'inizio tutti i sentieri nascosti e i passaggi segreti del Reame.'),
'inseguitrice':('SEGUGIO','Nelle dieci tessere di bosco tira un solo dado per nascondersi e per tutte le tabelle di ricerca.'),
}
DW={'Inn':'locanda','Guard':'corpo_guardia','House':'casa','Hut':'capanna','Cottage':'casolare','Hamlet':'borgo','Settlement':'insediamento','Chapel':'cappella'}
def chit(s):
    s=s.strip()
    m=re.fullmatch(r'(Move|Fight|Berserk|Reflex|Duck) ([LMHT])(\d)(\**)',s)
    if m:
        t={'Move':'M','Fight':'F','Berserk':'B','Reflex':'R','Duck':'D'}[m.group(1)]
        return dict(tipo=t,forza=m.group(2),vel=int(m.group(3)),sforzi=len(m.group(4)))
    m=re.fullmatch(r'([IVX]+)(\d)(\**)',s)
    return dict(tipo='G',magia=m.group(1),vel=int(m.group(2)),sforzi=len(m.group(3)))
CARTE={10:'Psychic',11:'Wizard',12:'Witch King',13:'Swordsman',14:'White Knight',15:'Woods Girl',16:'Dwarf',17:'Sorcerer',18:'Captain',19:'Magician',
20:'Black Knight',21:'Elf',22:'Berserker',23:'Amazon',24:'Gladiator',25:'Druid',26:'Necromancer',27:'Bard',28:'Pilgrim',29:'Witch',30:'Trawler',31:'Paladin',32:'Wanderer',33:'Barbarian'}
en2card={v:k for k,v in CARTE.items()}
out=[]
for k,(nome,en,peso,vuln,part,ch,eq,ab) in RAW.items():
    assert len(ch)==12,k
    chits=[chit(x) for x in ch]
    nmag=sum(1 for c in chits if c['tipo']=='G')
    armi=[e for e in eq if e not in ('elmo','corazza','scudo','armatura')]
    out.append(dict(id=k,nome=nome,nome_en=en,peso=peso,vuln=vuln,partenze=[DW[p] for p in part],chits=chits,equip=eq,
      abilita=[dict(id=a,nome=ABIL[a][0],testo=ABIL[a][1]) for a in ab],
      combattente=bool(armi) and nmag<2, magia=nmag,
      pedina=re.sub(r'[^a-z]','_',en.lower())))
    c=en2card[en]
    im=Image.open('charcards/c%02d_a.jpg'%c).convert('RGB')
    W,H=im.size
    sq=im.crop((int(W*0.12),int(H*0.17),int(W*0.88),int(H*0.17)+int(W*0.76)))
    sq.resize((300,300),Image.LANCZOS).save('/home/claude/magic-realm/assets/personaggi/%s_simbolo.webp'%re.sub(r'[^a-z]','_',en.lower()),'WEBP',quality=85)
json.dump(out,open('/home/claude/magic-realm/data/personaggi.json','w'),ensure_ascii=False,indent=1)
print([ (o['id'],o['combattente']) for o in out])
