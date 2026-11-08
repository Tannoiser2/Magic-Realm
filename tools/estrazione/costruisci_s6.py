import sys,json
sys.path.insert(0,'.')
from tts import *
from PIL import Image
A='/home/claude/magic-realm/assets/viaggiatori/'
N=[('apprentice','Apprendista','N',{'undado':'rune'}),('dominate','Dominare','C',{}),('seek','Ricerca','T',{'siti':['altar','cairns','maze','spire']}),
 ('confront','Affrontare','C',{}),('raid','Razzia','C',{}),('challenge','Sfida','C',{}),('food_ale','Cibo e birra','M',{'dest':'locanda','alt':'casa'}),
 ('war','Guerra','C',{}),('blacksmith','Fabbro','V',{}),('cleric','Chierico','V',{}),('liberate','Liberare','C',{}),('strongman','Forzuto','N',{'chit':['M','T',5],'chiave':True}),
 ('hermit','Eremita','N',{'fase':'M'}),('fairy','Fata','N',{'fase':'A','fiuto':True}),('revolt','Rivolta','C',{}),('pillage','Saccheggio','C',{}),
 ('escort_party','Scorta','M',{'dest':'cappella','alt':'corpo_guardia'}),('skirmish','Schermaglia','C',{}),('books_art','Libri e arte','M',{'dest':'insediamento','alt':'borgo'}),
 ('barkeep','Oste','N',{'undado':'incontro'}),('conquer','Conquista','C',{}),('warlock','Stregone errante','V',{}),('initiate','Iniziato','N',{'fase':'E'}),
 ('odyssey','Odissea','T',{'siti':['den','garden','pool','vault']}),('ranger','Guardaboschi','N',{'undado':'nascondi'}),('crone','Vecchia strega','V',{}),('priest','Sacerdote','V',{}),
 ('quest','Impresa','C',{}),('miner','Minatore','N',{'fase':'grotta'}),('hunt','Caccia','C',{}),('scholar','Studioso','V',{}),
 ('journey','Viaggio','T',{'siti':['hoard','statue','tomb','tower']}),('explore','Esplorazione','T',{'siti':['lair','pit','shrine','temple']}),
 ('shadow','Ombra','N',{'fase':'S'}),('merchant','Mercante','V',{}),('tour_guide','Guida turistica','M',{'dest':'capanna','alt':'casolare'}),
 ('bargainer','Contrattatore','N',{'undado':'incontro'}),('shaman','Sciamano','V',{}),('tracker','Segugio','N',{'undado':'cerca'}),('cook','Cuoco','N',{'riposo':'doppio'})]
out={}
i=0
for o,p in walk():
    if p and p[0]=='Travelers':
        ci=o['CustomImage']
        k,it,t,e=N[i]
        im=Image.open(loc(ci['ImageURL'])).convert('RGB'); im.thumbnail((150,150)); im.save(A+k+'.webp',quality=85)
        if i==0:
            im=Image.open(loc(ci['ImageSecondaryURL'])).convert('RGB'); im.thumbnail((150,150)); im.save(A+'retro.webp',quality=85)
        out[k]={'nome':it,'tipo':t,'eff':e,'img':'viaggiatori/'+k+'.webp'}
        i+=1
json.dump(out,open('/home/claude/magic-realm/data/viaggiatori.json','w'),ensure_ascii=False,indent=0)
print(i)
