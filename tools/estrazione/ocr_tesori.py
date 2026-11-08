import sys,json,re;sys.path.insert(0,'.')
from tts import *
import pytesseract
decks=[o for o,p in walk() if o['Name']=='Deck' and not p]
out=[]
for di,kind in ((21,'S'),(22,'L'),(23,'TWT')):
    d=decks[di]
    for i,c in enumerate(d['ContainedObjects']):
        c.setdefault('CustomDeck',d['CustomDeck'])
        im=card_img(c); w,h=im.size
        top=im.crop((0,int(h*0.04),w,int(h*0.62))).resize((w*2,int(h*0.58)*2))
        t=pytesseract.image_to_string(top)
        im.save(f'/home/claude/lavoro/s4/t_{kind}_{i:03d}.png')
        out.append({'k':kind,'i':i,'ocr':t})
json.dump(out,open('/home/claude/lavoro/s4/ocr.json','w'),indent=0)
