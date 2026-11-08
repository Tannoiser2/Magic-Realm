import json,re,os,glob
BASE='/home/claude/src_mr/Mods'
D=json.load(open(BASE+'/Workshop/1248055332.json'))
_idx={}
for f in glob.glob(BASE+'/Images/*')+glob.glob(BASE+'/Models/*')+glob.glob(BASE+'/PDF/*'):
    _idx[os.path.splitext(os.path.basename(f))[0]]=f
def loc(url):
    if not url: return None
    k=re.sub(r'[^A-Za-z0-9]','',url)
    if k in _idx: return _idx[k]
    for kk,v in _idx.items():
        if kk.startswith(k) or k.startswith(kk): return v
    return None
def walk(objs=None,path=()):
    for o in (D['ObjectStates'] if objs is None else objs):
        yield o,path
        if o.get('ContainedObjects'):
            yield from walk(o['ContainedObjects'],path+(o.get('Nickname') or o['Name'],))
from PIL import Image as _I
_I.MAX_IMAGE_PIXELS=None
_sheets={}
def card_img(o, back=False):
    cid=o['CardID']; dk=str(cid//100); idx=cid%100
    v=o['CustomDeck'][dk]
    f=loc(v['BackURL'] if back else v['FaceURL'])
    if f not in _sheets: _sheets[f]=_I.open(f).convert('RGB')
    s=_sheets[f]; w=s.width//v['NumWidth']; h=s.height//v['NumHeight']
    if back and not v.get('UniqueBack'): 
        if v['NumWidth']>1 and s.width>w*1.5: pass
        else: return s
    return s.crop(((idx%v['NumWidth'])*w,(idx//v['NumWidth'])*h,(idx%v['NumWidth']+1)*w,(idx//v['NumWidth']+1)*h))
