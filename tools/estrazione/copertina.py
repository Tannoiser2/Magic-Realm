# Compone la copertina (menu e ludoteca) con tessere e pedine originali. Da eseguire dentro assets/.
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance
import math, glob, random
random.seed(7)
def hexmap(W,H,R,ox,oy,order):
    im=Image.new('RGBA',(W,H),(0,0,0,0)); k=0
    for q in range(-6,7):
        for r in range(-6,7):
            x=ox+1.5*R*q; y=oy+math.sqrt(3)*R*(r+q/2)
            if -R<x<W+R and -R<y<H+R:
                t=Image.open('tessere/t%02d.webp'%order[k%40]).convert('RGBA').resize((int(2*R),int(2*R)))
                im.alpha_composite(t.rotate(60*random.randint(0,5)),(int(x-R),int(y-R))); k+=1
    return im
order=list(range(40)); random.shuffle(order)
def cover(W,H,R,ts,file,vert):
    bg=Image.new('RGBA',(W,H),(26,17,11,255))
    bg.alpha_composite(ImageEnhance.Brightness(hexmap(W,H,R,W/2,H/2,order)).enhance(0.8))
    vg=Image.new('L',(W,H),0); d=ImageDraw.Draw(vg)
    for i in range(60): d.rectangle((i*W/140,i*H/140,W-i*W/140,H-i*H/140),fill=int(255*i/60))
    vg=vg.filter(ImageFilter.GaussianBlur(40))
    dark=Image.new('RGBA',(W,H),(15,9,5,235)); dark.putalpha(Image.eval(vg,lambda v:255-v)); bg.alpha_composite(dark)
    mons=['drago_t','drago_volante_t','gigante','troll_t','demone_alato']; imgs={}
    for f in sorted(glob.glob('mostri/*_a.webp')):
        n=f.split('/')[-1]
        for mm in mons:
            if n.startswith(mm+'_') and mm not in imgs: imgs[mm]=f
    pos=[(0.18,0.66),(0.82,0.66),(0.30,0.86),(0.70,0.86),(0.5,0.70)] if vert else [(0.12,0.68),(0.88,0.66),(0.27,0.84),(0.73,0.84),(0.5,0.82)]
    for (px,py),mm in zip(pos,mons):
        c=Image.open(imgs[mm]).convert('RGBA'); s=int(min(W,H)*0.21); c=c.resize((s,s)).rotate(random.uniform(-12,12),expand=True)
        sh=Image.new('RGBA',c.size,(0,0,0,0)); ImageDraw.Draw(sh).rectangle((8,8,c.width-8,c.height-8),fill=(0,0,0,150)); sh=sh.filter(ImageFilter.GaussianBlur(8))
        bg.alpha_composite(sh,(int(px*W-c.width/2+8),int(py*H-c.height/2+8))); bg.alpha_composite(c,(int(px*W-c.width/2),int(py*H-c.height/2)))
    ped=Image.open('personaggi/amazon_pedina.webp').convert('RGBA').resize((int(min(W,H)*0.17),)*2)
    bg.alpha_composite(ped,(int(W*0.5-ped.width/2),int(H*(0.43 if vert else 0.46))))
    d=ImageDraw.Draw(bg); f=ImageFont.truetype('font/Titoli.ttf',ts)
    t='Magic Realm'; w=d.textlength(t,font=f); y=int(H*0.10)
    for dx,dy in [(-3,0),(3,0),(0,-3),(0,3),(4,4)]: d.text(((W-w)/2+dx,y+dy),t,font=f,fill=(20,8,4,255))
    d.text(((W-w)/2,y),t,font=f,fill=(232,190,90,255))
    f2=ImageFont.truetype('font/Fell.ttf',int(ts*0.36)); t2='Super Realm'; w2=d.textlength(t2,font=f2)
    d.text(((W-w2)/2+2,y+ts*1.05+2),t2,font=f2,fill=(0,0,0,255)); d.text(((W-w2)/2,y+ts*1.05),t2,font=f2,fill=(240,225,190,255))
    bg.convert('RGB').save(file,'WEBP',quality=86)
cover(1600,1000,150,170,'ui/copertina.webp',False)
cover(540,720,95,78,'../ludoteca/copertina.webp',True)
