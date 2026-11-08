import sys,json,re;sys.path.insert(0,'.')
from tts import *
import pytesseract
from PIL import Image
out=[];sheet=[]
def rec(objs,typ=None,cd=None):
    for o in objs:
        nk=o.get('Nickname') or ''
        t=nk.split()[0] if 'Spell Deck' in nk else typ
        c=o.get('CustomDeck') or cd
        if o['Name']=='Card' and t:
            o.setdefault('CustomDeck',c)
            im=card_img(o)
            n=sum(1 for x in out if x['t']==t)
            im.save(f'/home/claude/lavoro/s4/sp_{t}_{n:02d}.png')
            tx=pytesseract.image_to_string(im.resize((im.width*2,im.height*2)))
            out.append({'t':t,'i':n,'ocr':tx})
            if n==0: sheet.append(im.resize((200,280)))
        if o.get('ContainedObjects'): rec(o['ContainedObjects'],t,c)
rec(D['ObjectStates'])
json.dump(out,open('/home/claude/lavoro/s4/ocr_sp.json','w'),indent=0)
sh=Image.new('RGB',(200*len(sheet),280))
for i,im in enumerate(sheet): sh.paste(im,(200*i,0))
sh.save('/home/claude/lavoro/s4/sp_sheet.jpg')
print(len(out), sheet[0].size if sheet else '')
