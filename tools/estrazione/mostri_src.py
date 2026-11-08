import json
# lato: (attacco, mossa)  attacco es 'H4*' ; '' = nessun attacco ; 'V2' incantesimo
T={}
def m(k,nome,peso,chiaro,scuro,fama,noto,lung=(0,0),arm=False,vola=False,missile=(False,False),incant=None,extra=None,plur=None):
    T[k]=dict(nome=nome,plurale=plur or nome,peso=peso,chiaro=chiaro,scuro=scuro,fama=fama,noto=noto,lung=list(lung),armato=arm,vola=vola,missile=list(missile),incant=incant,extra=extra)
m('fantasma','Fantasma','M',('H4',4),('L2',2),0,2,plur='Fantasmi')
m('goblin_ascia',"Goblin con ascia",'M',('L4*',3),('M4*',4),1,1,(2,2),plur='Goblin con ascia')
m('goblin_arco',"Goblin con arco",'M',('',3),('L1**',5),1,1,(14,14),missile=(False,True),plur='Goblin con arco')
m('goblin_spadone',"Goblin con spadone",'M',('H6*',3),('T5*',5),1,1,(8,8),plur='Goblin con spadone')
m('goblin_lancia',"Goblin con lancia",'M',('',3),('H5*',5),1,1,(10,10),plur='Goblin con lancia')
m('imp','Imp','M',('V2',2),('M4',3),2,1,(17,0),incant='maledizione',plur='Imp')
m('orco_m','Orco','M',('T5',5),('H5',4),0,2,plur='Orchi')  # Ogre
m('ratto_a','Ratto','M',('M4',4),('L4',3),0,1,plur='Ratti')
m('ratto_b','Ratto','M',('L3',4),('M5',3),0,1,plur='Ratti')
m('scheletro_ascia','Scheletro con ascia','M',('H6*',4),('H5*',5),1,2,(5,5),arm=True,plur='Scheletri con ascia')
m('scheletro_arco','Scheletro con arco','M',('',3),('L1**',5),1,2,(14,14),arm=True,missile=(False,True),plur='Scheletri con arco')
m('scheletro_lancia','Scheletro con lancia','M',('M4*',4),('H6*',5),1,2,(10,10),arm=True,plur='Scheletri con lancia')
m('scheletro_spada','Scheletro con spada','M',('L4*',4),('M4*',5),1,2,(4,4),arm=True,plur='Scheletri con spada')
m('succubo','Succube','M',('V2',2),('M3',4),2,1,(17,0),incant='ipnosi',plur='Succubi')
m('vipera','Vipera','M',('M4**',4),('L2',2),1,2,arm=True,plur='Vipere')
m('lupo_a','Lupo','M',('L4',3),('M4',4),0,1,plur='Lupi')
m('lupo_b','Lupo','M',('M5',3),('L3',4),0,1,plur='Lupi')
m('alligatore','Alligatore','H',('M4',3),('H4',4),4,4,arm=True,plur='Alligatori')
for c,cn in (('grigia','grigia'),('oro','dorata'),('viola','viola'),('prisma','prismatica')):
    m('anomalia_'+c,'Anomalia '+cn,'H',('M4',4),('L3**',5),4,4,(0,14),arm=True,missile=(False,True),plur='Anomalie')
m('orso','Orso','H',('H5',4),('M4',3),3,3,plur='Orsi')
m('drago','Drago','H',('H4',4),('M4',3),5,5,arm=True,plur='Draghi')
m('drago_volante','Drago volante','H',('H4',4),('L4',3),5,5,arm=True,vola=True,plur='Draghi volanti')
m('gargoyle','Gargoyle','H',('M4',3),('M3',4),4,4,arm=True,vola=True,plur='Gargoyle')
m('pipistrello','Pipistrello gigante','H',('M2',3),('M3',2),3,3,vola=True,plur='Pipistrelli giganti')
m('minotauro','Minotauro','H',('H5*',4),('H4*',5),5,5,(5,5),extra='scudo_minotauro',plur='Minotauri')
m('orco','Orco guerriero','H',('M4*',4),('H5*',3),3,3,(8,8),plur='Orchi guerrieri')
m('scorpione','Scorpione','H',('M4*',4),('H5*',4),5,5,arm=True,plur='Scorpioni')
m('serpente','Serpente','H',('M4',3),('H5',4),4,4,arm=True,plur='Serpenti')
m('cavaliere_scheletro','Cavaliere scheletro','H',('H4*',5),('T5*',5),5,5,(8,8),arm=True,extra='cavallo_scheletro',plur='Cavalieri scheletro')
m('ragno','Ragno','H',('L4',3),('T6',4),3,3,plur='Ragni')
m('troll','Troll','H',('M4',4),('H5',4),5,5,arm=True,plur='Troll')
m('vampiro','Vampiro','H',('V2',4),('M4',3),4,4,(17,0),arm=True,vola=True,incant='ipnosi',plur='Vampiri')
m('spettro','Spettro','H',('L3',3),('T5',5),3,3,plur='Spettri')
m('demone','Demone','T',('V2',4),('X4',4),8,8,(17,0),incant='abisso',plur='Demoni')
m('drago_t','Drago tremendo','T',('H5',6),('X3',6),10,10,arm=True,extra='testa_drago',plur='Draghi tremendi')
m('drago_volante_t','Drago volante tremendo','T',('M3',4),('X6',4),12,12,arm=True,vola=True,extra='testa_drago_volante',plur='Draghi volanti tremendi')
m('gargoyle_t','Gargoyle tremendo','T',('H5',3),('X4',4),8,8,arm=True,vola=True,plur='Gargoyle tremendi')
m('gigante','Gigante','T',('H5',5),('X4',6),8,8,extra='clava',plur='Giganti')
m('baccello','Baccello gigante','T',('H6',5),('X3',6),8,8,extra='liana',plur='Baccelli giganti')
m('golem','Golem','T',('H4',4),('X4',4),8,8,arm=True,plur='Golem')
m('piovra','Piovra','T',('L4',2),('X4',3),8,8,plur='Piovre')
m('scorpione_t','Scorpione tremendo','T',('M5',5),('X4',5),10,10,arm=True,extra='pungiglione',plur='Scorpioni tremendi')
m('serpente_t','Serpente tremendo','T',('L4',4),('X4',5),7,7,arm=True,plur='Serpenti tremendi')
m('ragno_t','Ragno tremendo','T',('M4',3),('X5',4),6,6,plur='Ragni tremendi')
m('troll_t','Troll tremendo','T',('H4',4),('X2',6),8,8,arm=True,plur='Troll tremendi')
m('demone_alato','Demone alato','T',('V3',3),('X5',2),8,8,(17,0),vola=True,incant='abisso',plur='Demoni alati')
m('colosso','Colosso','X',('X5',0),('X5',0),15,15,arm=True,plur='Colossi')
m('titano','Titano','X',('M4***',0),('M4***',0),15,15,(18,18),arm=True,missile=(True,True),plur='Titani')
# contatori aggiuntivi (non attaccabili)
X={}
X['testa_drago']=dict(nome='Testa del drago',chiaro=('H4',0),scuro=('T4',0),lung=[9,9])
X['testa_drago_volante']=dict(nome='Testa del drago volante',chiaro=('M3',0),scuro=('T3',0),lung=[7,7])
X['clava']=dict(nome='Clava del gigante',chiaro=('H6',0),scuro=('T4',0),lung=[8,8])
X['liana']=dict(nome='Liana del baccello',chiaro=('M4*',0),scuro=('H4*',0),lung=[6,6])
X['pungiglione']=dict(nome='Pungiglione',chiaro=('L4**',0),scuro=('M4**',0),lung=[6,6])
X['scudo_minotauro']=dict(nome='Scudo del minotauro',peso='T')
X['cavallo_scheletro']=dict(nome='Destriero scheletro',peso='T',chiaro=('',6),scuro=('',4),armato=True)
mappa=[(r'Wolf, medium','lupo'),(r'Rat, medium','ratto'),(r'Ghost, medium','fantasma'),(r'Goblin with Axe.*','goblin_ascia'),
(r'Goblin with Bow.*','goblin_arco'),(r'Goblin with Great Sword.*','goblin_spadone'),(r'Goblin with Spear.*','goblin_lancia'),
(r'Imp.*','imp'),(r'Ogre.*','orco_m'),(r'Skeleton with Axe.*','scheletro_ascia'),(r'Skeleton with Bow.*','scheletro_arco'),
(r'Skeleton with Spear.*','scheletro_lancia'),(r'Skeleton with Sword.*','scheletro_spada'),(r'Succubus.*','succubo'),(r'Viper.*','vipera'),
(r'Alligator.*','alligatore'),(r'Grey Anomaly.*','anomalia_grigia'),(r'Gold Anomaly.*','anomalia_oro'),(r'Purple Anomaly.*','anomalia_viola'),
(r'Prism Anomaly.*','anomalia_prisma'),(r'Bear','orso'),(r'Dragon, heavy.*','drago'),(r'Flying Dragon, heavy.*','drago_volante'),
(r'Gargoyle, heavy.*','gargoyle'),(r'Giant Bat.*','pipistrello'),(r'Minotaur, heavy','minotauro'),(r'Orc.*','orco'),
(r'Scorpion, heavy.*','scorpione'),(r'Serpent, heavy.*','serpente'),(r'Skeleton Knight.*','cavaliere_scheletro'),(r'Spider, heavy','ragno'),
(r'Troll, heavy.*','troll'),(r'Vampire.*','vampiro'),(r'Wraith.*','spettro'),(r'Demon, tremendous','demone'),(r'Dragon, tremendous.*','drago_t'),
(r'Flying Dragon, tremendous.*','drago_volante_t'),(r'Gargoyle, tremendous.*','gargoyle_t'),(r'Giant, tremendous','gigante'),
(r'Giant Pod, tremendous','baccello'),(r'Golem.*','golem'),(r'Octopus.*','piovra'),(r'Scorpion, tremendous.*','scorpione_t'),
(r'Serpent, tremendous.*','serpente_t'),(r'Spider, tremendous','ragno_t'),(r'Troll, tremendous.*','troll_t'),(r'Winged Demon.*','demone_alato'),
(r'Colossus.*','colosso'),(r'Titan.*','titano'),(r'Dragon Head','testa_drago'),(r'Flying Dragon Head','testa_drago_volante'),
(r"Giant's Club",'clava'),(r'Pod Vine','liana'),(r'Scorpion Stinger','pungiglione'),(r'Minotaur Shield.*','scudo_minotauro'),
(r'Skeleton Horse.*','cavallo_scheletro')]
# Tabella delle apparizioni: gruppi (riga, sezione, mostri [tipo,numero] per riquadro, segnalini che evocano)
# chiave segnalino: NOME_LETTERA (avvisi) o NOME_* / NOME_LETTERA (suoni rossi: * = qualsiasi tessera)
G=[]
def g(riga,sez,box,chit): G.append(dict(riga=riga,sezione=sez,riquadri=box,segnalini=chit))
g(1,'castello',[[['drago_volante',1]],[['drago_volante',2]],[['drago_volante_t',1]]],['SMOKE_M','FLUTTER_*'])
g(2,'castello',[[['vipera',2]]],['DANK_W'])
g(3,'castello',[[['lupo',6]]],['RUINS_W'])
g(3,'castello',[[['orco_m',2]]],['BONES_W'])
g(4,'castello',[[['gigante',1]],[['gigante',1]],[['gigante',1]]],['BONES_M','STINK_M','ROAR_M'])
g(5,'castello',[[['ragno',1]],[['ragno',1]],[['ragno',1]],[['ragno',1]]],['STINK_M','DANK_M','PATTER_M'])
g(6,'castello',[[['pipistrello',1]],[['pipistrello',2]],[['pipistrello',2]],[['pipistrello',3]]],['RUINS_M','BONES_M','FLUTTER_*','HOWL_M'])
g(1,'citta',[[['drago',1]],[['drago',2]],[['drago_t',1]]],['SMOKE_C','SLITHER_*','ROAR_C'])
g(2,'citta',[[['serpente',1]],[['serpente',2]],[['serpente_t',1]]],['DANK_C','SLITHER_*'])
g(3,'citta',[[['goblin_ascia',6]],[['goblin_lancia',6]],[['goblin_spadone',6]],[['goblin_arco',6]]],['RUINS_C','PATTER_C','HOWL_C'])
g(4,'citta',[[['troll',1]],[['troll',2]],[['troll_t',1]]],['BONES_C','STINK_C','ROAR_C'])
g(1,'palazzo',[[['scorpione',1]],[['scorpione',2]],[['scorpione_t',1]]],['DANK_F','STINK_F','PATTER_F'])
g(2,'palazzo',[[['spettro',1]],[['spettro',1]],[['spettro',1]],[['spettro',1]]],['RUINS_F','BONES_F','HOWL_*','FLUTTER_F'])
g(3,'palazzo',[[['ratto',6]]],['RUINS_S'])
g(3,'palazzo',[[['orso',1]]],['BONES_S'])
g(4,'palazzo',[[['alligatore',1]]],['DANK_S'])
g(5,'palazzo',[[['anomalia_grigia',1]],[['anomalia_oro',1]],[['anomalia_viola',1]],[['anomalia_prisma',1]]],['SMOKE_F','HOWL_*'])
g(6,'palazzo',[[['baccello',1]],[['baccello',1]],[['baccello',1]]],['DANK_F','BONES_F','SLITHER_F'])
g(3,'fortezza',[[['gargoyle',1]],[['gargoyle',2]],[['gargoyle_t',1]]],['STINK_R','FLUTTER_R','SLITHER_R'])
g(4,'fortezza',[[['scheletro_spada',6]],[['scheletro_lancia',6]],[['scheletro_ascia',6]],[['scheletro_arco',6]]],['BONES_R','DANK_R','PATTER_R'])
g(5,'fortezza',[[['orco',1]],[['orco',2]],[['orco',2]],[['orco',3]]],['SMOKE_R','ROAR_*','PATTER_R'])
g(6,'fortezza',[[['golem',1]],[['golem',1]],[['golem',1]]],['RUINS_R','ROAR_*'])
SITI={'hoard':(1,'drago_volante_t'),'lair':(1,'drago_t'),'pit':(1,'scorpione_t'),'altar':(2,'demone'),'shrine':(2,'demone_alato'),
 'den':(2,'serpente_t'),'pool':(3,'piovra'),'tower':(3,'colosso'),'vault':(4,'troll_t'),'tomb':(4,'cavaliere_scheletro'),
 'cairns':(5,'ragno_t'),'statue':(5,'imp'),'spire':(5,'titano'),'garden':(6,'succubo'),'maze':(6,'minotauro'),'temple':(6,'vampiro')}
RIGHE={1:'Draghi e scorpioni',2:'Serpenti, spettri e demoni',3:'Lupi, goblin, orchi, ratti, orso, piovra, gargoyle e colosso',
 4:'Alligatore, giganti, scheletri e troll',5:'Ragni, anomalie, orchi guerrieri, imp e titano',6:'Pipistrelli, golem, baccelli, vampiro, succube e minotauro'}
json.dump(dict(tipi=T,extra=X,gruppi=G,siti=SITI,righe=RIGHE,_mappa=mappa),open('mostri_def.json','w'),ensure_ascii=False,indent=1)
print(len(T),'tipi')
