#!/usr/bin/env python3
"""Reproducible original Reelworks vector art and synthesized audio. No source media."""
from pathlib import Path
import math, random, struct, wave, shutil
ROOT=Path(__file__).resolve().parents[1]
A=ROOT/'assets'
random.seed(1998)
for p in ['cabinets','symbols','audio','fonts']: (A/p).mkdir(parents=True,exist_ok=True)

def svg(body, w=680,h=580,defs=''):
 return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><defs>
 <linearGradient id="gold" x2="0.2" y2="1"><stop stop-color="#fff5be"/><stop offset=".3" stop-color="#e8bc59"/><stop offset=".55" stop-color="#987039"/><stop offset=".78" stop-color="#eac774"/><stop offset="1" stop-color="#71512a"/></linearGradient>
 <linearGradient id="cream" x2=".1" y2="1"><stop stop-color="#fff7d9"/><stop offset="1" stop-color="#bba77b"/></linearGradient>
 <linearGradient id="metal" x2=".3" y2="1"><stop stop-color="#98b5c9"/><stop offset=".3" stop-color="#253650"/><stop offset=".6" stop-color="#8aacc3"/><stop offset="1" stop-color="#17243a"/></linearGradient>
 <linearGradient id="red" x2=".2" y2="1"><stop stop-color="#ff7360"/><stop offset=".4" stop-color="#dd352f"/><stop offset="1" stop-color="#821a27"/></linearGradient>
 <linearGradient id="green" x2=".4" y2="1"><stop stop-color="#519c76"/><stop offset=".5" stop-color="#216044"/><stop offset="1" stop-color="#102e2d"/></linearGradient>
 {defs}</defs>{body}</svg>'''
def path(d,fill='none',stroke=None,sw=1,other=''):
 return f'<path d="{d}" fill="{fill}"'+(f' stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round" stroke-linecap="round"' if stroke else '')+f' {other}/>'
def rect(x,y,w,h,fill,stroke=None,sw=1,rx=0):
 return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}"'+(f' stroke="{stroke}" stroke-width="{sw}"' if stroke else '')+'/>'
def circle(x,y,r,fill,stroke=None,sw=1):
 return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}"'+(f' stroke="{stroke}" stroke-width="{sw}"' if stroke else '')+'/>'
def ellipse(x,y,rx,ry,fill,stroke=None,sw=1):
 return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}"'+(f' stroke="{stroke}" stroke-width="{sw}"' if stroke else '')+'/>'
def group(body,t): return f'<g transform="{t}">{body}</g>'
def star(x,y,r,fill='#ffe798',n=5):
 points=[]
 for i in range(n*2):
  a=i*math.pi/n-math.pi/2;rr=r if i%2==0 else r*.42
  points.append((x+rr*math.cos(a),y+rr*math.sin(a)))
 return path('M'+' L'.join(f'{x:.1f} {y:.1f}' for x,y in points)+'Z',fill)
def rayfan(cx,cy,colors):
 out=''
 for i in range(24):
  a=i*math.tau/24;b=(i+.65)*math.tau/24
  out+=path(f'M{cx} {cy} L{cx+900*math.cos(a):.2f} {cy+900*math.sin(a):.2f} L{cx+900*math.cos(b):.2f} {cy+900*math.sin(b):.2f}Z', colors[i%len(colors)])
 return out

def border(bg,light,inner):
 out=rect(0,0,680,580,bg)+rect(8,8,664,564,'none',light,3,30)+rect(17,17,646,546,'none',inner,1,25)
 for x,y in [(29,29),(651,29),(29,551),(651,551)]:
  out+=circle(x,y,6,'url(#gold)','#382d20',1)+path(f'M{x-3} {y+2} L{x+3} {y-2}','none','#4b422d',1)
 for y in [65,515]:
  out+=path(f'M36 {y} Q88 {y-20} 145 {y} M535 {y} Q592 {y-20} 644 {y}','none',light,2)
  out+=path(f'M42 {y+8} Q90 {y-8} 138 {y+8} M542 {y+8} Q590 {y-8} 638 {y+8}','none',inner,1)
 return out

def barrel(x=0,y=0,scale=1):
 b=path('M8 9 Q38 -1 68 9 Q80 49 68 89 Q38 99 8 89 Q-4 49 8 9Z','#a6602d','#341d19',4)
 for i in [16,30,46,60]: b+=path(f'M{i} 8 Q{i-8 if i<38 else i+8} 48 {i} 90','none','#d58d43',3)
 for yy in [20,70]: b+=path(f'M3 {yy} Q38 {yy+12} 73 {yy} L74 {yy+10} Q38 {yy+22} 2 {yy+10}Z','url(#gold)','#55391d',2)
 b+=ellipse(38,8,31,8,'#d49b58','#55351c',2)
 return group(b,f'translate({x} {y}) scale({scale})')

def pub():
 defs='<radialGradient id="warm"><stop stop-color="#e79f39"/><stop offset=".58" stop-color="#a55228"/><stop offset="1" stop-color="#2b352b"/></radialGradient><linearGradient id="roof" x2="0" y2="1"><stop stop-color="#ca5739"/><stop offset="1" stop-color="#6c2c2c"/></linearGradient><linearGradient id="window" x2="0" y2="1"><stop stop-color="#fff09a"/><stop offset="1" stop-color="#ec963b"/></linearGradient>'
 out=border('#1b302b','#c69b50','#4f6a4b')
 out+=rect(36,80,608,429,'url(#warm)',rx=80)
 out+=f'<g opacity=".10">{rayfan(340,320,["#ffdb66","#1e392b"])}</g>'
 out+=ellipse(340,333,221,192,'none','#e0ad55',3)+ellipse(340,333,212,185,'none','#694827',2)
 for x,y,r in [(142,163,9),(537,183,10),(169,444,8),(534,448,8),(326,142,11),(188,205,5),(485,135,5)]: out+=star(x,y,r)
 out+=ellipse(350,458,168,23,'#202b25')
 # crooked original half timber pub
 out+=path('M219 294 L418 267 L464 316 L450 433 L235 455Z','url(#cream)','#3d2a22',5)
 out+=path('M418 267 L481 309 L465 429 L450 433 L464 316Z','#ae7343','#3d2a22',4)
 out+=path('M194 298 L259 192 L402 181 L479 288 L418 307 L267 274Z','url(#roof)','#382721',5)
 out+=path('M194 298 L259 192 L402 181 M259 192 L267 274 L418 307','none','#ff9e56',3)
 # tiled roof
 for k in range(5):
  yy=204+k*15
  out+=path(f'M{255-k*8} {yy} L{412+k*9} {yy-12}','none','#642a26',2)
 for k in range(7):
  xx=264+k*22
  out+=path(f'M{xx} 197 L{xx+22} 285','none','#813026',1)
 out+=path('M374 188 L369 145 L398 139 L407 184Z','#ac7346','#382721',3)+path('M366 146 L365 137 L400 131 L403 140Z','url(#cream)','#382721',3)
 out+=path('M383 132 Q359 117 386 106 Q407 100 394 84','none','#e7c08c',8,other='opacity=".23"')
 # gable + timber beams
 out+=path('M211 302 L267 222 L327 290Z','#e8be7b','#452c23',5)
 out+=path('M267 222 L269 317 M228 285 L304 285 M238 268 L295 309 M293 258 L241 316','none','#57352a',8)
 out+=path('M235 330 L453 306 M239 411 L450 388 M247 322 L252 446 M336 320 L340 435 M419 310 L415 429','none','#50352a',8)
 out+=path('M254 413 L337 333 M339 432 L419 318','none','#69422a',5)
 # windows
 for xx,yy in [(271,334),(360,323)]:
  out+=rect(xx,yy,43,53,'url(#window)','#463126',5,13)
  out+=path(f'M{xx+21} {yy+3} L{xx+21} {yy+50} M{xx+3} {yy+27} L{xx+40} {yy+27}','none','#744629',3)
  out+=rect(xx-5,yy+50,53,8,'url(#gold)','#432b22',2,2)
 out+=path('M284 447 L282 399 Q303 377 322 397 L324 439Z','#1e4b3b','#402a24',5)+circle(315,419,3,'#ffe5a1')
 out+=path('M275 454 L332 445 L339 455 L272 465Z','url(#cream)','#594331',2)
 # hanging pub sign featuring original little mug
 out+=path('M420 301 L435 248 L479 252','none','#2e2727',6)+path('M437 250 Q457 235 476 252','none','#d1a45a',2)
 out+=path('M452 255 L450 268 M474 257 L474 270','none','#c9a261',2)
 sign=rect(442,267,43,45,'#264d3c','url(#gold)',4,4)+path('M455 281 L469 281 L468 301 L456 301Z','#eda64c','#ffe6a4',2)+path('M469 284 Q480 281 477 293 Q476 297 469 295','none','#f2ce7f',3)
 out+=sign
 # lanterns, flora, ground
 for xx,yy in [(227,318),(442,313)]:
  out+=path(f'M{xx} {yy} L{xx} {yy+11}','none','#261f21',3)+path(f'M{xx-7} {yy+11} L{xx+7} {yy+11} L{xx+5} {yy+28} L{xx-5} {yy+28}Z','#ffdc68','#3a2a25',3)
 out+=barrel(170,389,.7)+barrel(453,377,.78)
 for xx,yy in [(207,444),(475,448),(240,466)]:
  out+=path(f'M{xx} {yy} q-22 -31 -35 -22 q1 24 35 22 q-2 -38 13 -38 q17 18 -13 38 q22 -19 33 -12 q-6 15 -33 12','#4f8546','#1e3a2c',2)
 # darts, beer foam details in upper corners
 dart=path('M0 0 L54 54','none','#f4d6a7',4)+path('M0 0 L20 3 L14 20Z','#d64538','#ffd48c',2)+path('M54 54 L62 62','none','#fff7da',2)
 out+=group(dart,'translate(145 245) rotate(-25)')+group(dart,'translate(502 219) rotate(105)')
 # decorative crest header to leave root title space
 out+=path('M185 70 Q340 27 495 70 L474 106 Q340 83 206 106Z','#173d32','url(#gold)',3)
 out+=path('M239 517 Q340 542 441 517','none','#edbc62',2)
 out+=star(340,526,7)
 return svg(out,defs=defs)

def building(x,y,w,h,color,roof=0):
 b=path(f'M{x} {y} L{x+w} {y} L{x+w+16} {y+10} L{x+w+16} {y+h} L{x+w} {y+h+8} L{x} {y+h}Z',color,'#102f35',3)
 b+=path(f'M{x+w} {y} L{x+w+16} {y+10} L{x+w+16} {y+h} L{x+w} {y+h+8}Z','#1b594d','#0e3436',2)
 if roof: b+=path(f'M{x-5} {y} L{x+w/2} {y-roof} L{x+w+5} {y}Z','url(#gold)','#153f3e',3)
 b+=rect(x-3,y+h-11,w+5,12,'url(#gold)','#183d38',2)
 for wy in range(int(y+15),int(y+h-15),22):
  for wx in range(int(x+8),int(x+w-6),16):
   b+=rect(wx,wy,7,12,'#f9db85' if (wx+wy)%3 else '#3b7f6a','#132f30',1)
 return b

def empire():
 defs='<radialGradient id="city"><stop stop-color="#257565"/><stop offset="1" stop-color="#0c2638"/></radialGradient>'
 out=border('#0b2431','#c3ad6b','#245649')+rect(36,80,608,429,'url(#city)',rx=70)
 # art deco fan scallops and grid
 for rr in [90,130,175,217]: out+=circle(340,302,rr,'none','#4a7f65',1)
 for i in range(16):
  a=i*math.tau/16
  out+=path(f'M340 302 L{340+225*math.cos(a):.1f} {302+202*math.sin(a):.1f}','none','#416d5c',1)
 out+=path('M135 446 L340 345 L559 449 L345 525Z','#163d37','#ba9852',3)
 out+=path('M151 449 L342 360 L542 449 L345 506Z','none','#47765c',2)
 for yy in range(398,502,22): out+=path(f'M{340-(yy-350)*1.8} {yy} L340 {yy-54} L{340+(yy-350)*1.8} {yy}','none','#365e4f',1)
 # rear and front original miniature buildings
 out+=building(191,307,43,112,'#508872',20)+building(413,280,50,153,'#5a947d',24)
 out+=building(250,249,46,173,'#a0b188',0)+building(373,256,43,162,'#a3ac7b',0)
 out+=building(305,205,61,230,'url(#cream)',28)
 out+=rect(315,178,41,30,'url(#gold)','#224637',3)+rect(323,160,25,20,'#84a38a','#254939',2)+path('M335 159 L335 123','none','#e8c984',3)
 out+=circle(335,126,4,'#fff2a3')
 # the atrium facade
 out+=path('M282 434 L389 434 L389 366 L335 337 L282 366Z','url(#cream)','#25483d',4)
 out+=path('M273 366 L335 327 L400 366Z','url(#gold)','#244438',4)
 for xx in [291,316,343,370]: out+=rect(xx,371,9,58,'#d0bd83','#43674e',2)
 out+=path('M321 431 L321 388 Q335 370 350 388 L350 431Z','#1b4b43','#b09c65',3)
 out+=rect(273,430,125,11,'url(#gold)','#244438',2)+rect(263,442,145,9,'url(#cream)','#244438',2)
 # park, boulevard, river reflected buildings
 out+=path('M191 462 Q251 440 285 468 Q310 482 326 481 L298 499 Q239 485 191 479Z','#23817b','#7bb3a2',2)
 for xx,yy in [(183,435),(459,452),(431,474),(225,463)]:
  out+=path(f'M{xx} {yy} L{xx} {yy-27}','none','#a29863',3)+circle(xx,yy-29,12,'#4b8d66','#153e35',2)+circle(xx-7,yy-23,8,'#579669')
 # original deco medal
 out+=path('M203 70 L238 55 L442 55 L477 70 L459 106 L221 106Z','#133d3a','url(#gold)',3)
 out+=path('M170 143 L194 143 L194 177 L216 177 M510 143 L486 143 L486 177 L464 177','none','#bca265',3)
 for x,y,r in [(173,230,6),(503,234,6),(224,170,4),(463,192,5),(337,94,7)]: out+=star(x,y,r)
 out+=path('M252 532 L279 520 L401 520 L428 532','none','#c7af6d',2)
 return svg(out,defs=defs)

def timeshift():
 defs='<radialGradient id="space"><stop stop-color="#4b296c"/><stop offset=".6" stop-color="#20265e"/><stop offset="1" stop-color="#111c34"/></radialGradient><radialGradient id="clockface"><stop stop-color="#24354c"/><stop offset="1" stop-color="#091b32"/></radialGradient><linearGradient id="electric" x2=".8" y2="1"><stop stop-color="#e4ffff"/><stop offset=".4" stop-color="#71e7ec"/><stop offset="1" stop-color="#1681b8"/></linearGradient>'
 out=border('#121a30','#7590aa','#44365a')+rect(36,80,608,429,'url(#space)',rx=70)
 for i in range(65):
  x=random.randint(85,595);y=random.randint(121,492)
  out+=circle(x,y,random.choice([.8,1,1.5]),'#8099b6')
 # field rings
 out+=ellipse(340,327,219,155,'none','#503f82',2)+ellipse(340,327,232,169,'none','#324b7b',1)
 out+=group(ellipse(340,327,226,72,'none','#7195b5',2),'rotate(-29 340 327)')
 # platform
 out+=ellipse(340,467,163,30,'#0c1a2e','#526584',3)+ellipse(340,456,163,30,'url(#metal)','#0c162b',4)+ellipse(340,455,138,22,'#263b55','#78a7bd',2)
 # coils and clock suspension
 for xx in [204,474]:
  out+=rect(xx-12,310,24,137,'url(#metal)','#11253c',3,7)
  for yy in range(324,432,12): out+=ellipse(xx,yy,23,7,'#3b4771','#92c4da',2)
  out+=ellipse(xx,305,34,14,'url(#metal)','#11253c',3)+ellipse(xx,295,25,10,'url(#metal)','#11253c',3)+circle(xx,281,13,'url(#electric)','#78dce9',2)
  out+=path(f'M{xx} 268 L{xx-14} 242 L{xx+10} 246 L{xx-12} 211 L{xx+20} 221 L{xx+5} 188','none','#60d8ef',4)
 # giant analog clock: original composition
 out+=circle(340,312,119,'#111b31','#d0b089',4)+circle(340,312,108,'url(#metal)','#10192e',5)+circle(340,312,94,'url(#clockface)','#68b9d7',3)
 for i in range(60):
  a=i*math.tau/60-math.pi/2;r1=78 if i%5==0 else 84;r2=88
  out+=path(f'M{340+r1*math.cos(a):.2f} {312+r1*math.sin(a):.2f} L{340+r2*math.cos(a):.2f} {312+r2*math.sin(a):.2f}','none','#8fd6db' if i%5 else '#f0ca8c',3 if i%5==0 else 1)
 for i in range(12):
  a=i*math.tau/12-math.pi/2;xx=340+68*math.cos(a);yy=312+68*math.sin(a)
  out+=circle(xx,yy,3,'#e9b975')
 out+=path('M340 312 L305 270 M340 312 L393 283','none','#f2d7a7',9)+path('M340 312 L330 369','none','#eb8264',3)+circle(340,312,10,'url(#gold)','#091a2c',3)
 # clock apex tubes
 out+=path('M300 211 L300 183 Q340 157 380 183 L380 211','none','#242b48',11)+path('M300 211 L300 183 Q340 157 380 183 L380 211','none','#7fb3cc',3)
 out+=rect(318,154,44,35,'url(#metal)','#0a1a2c',4,7)+circle(340,170,11,'#0b2f46','#99dae1',3)+circle(340,170,5,'#e09257')
 # left/right era orbit spheres
 for xx,yy,co in [(163,241,'#e8ab68'),(521,382,'#6de1e7'),(314,479,'#b590e2')]:
  out+=circle(xx,yy,16,'#18314a',co,3)+ellipse(xx,yy,25,7,'none',co,2)+circle(xx-5,yy-5,4,co)
 # cables and terminals
 out+=path('M243 421 Q243 455 291 446 M438 421 Q442 456 394 445','none','#de845c',5)
 out+=rect(292,432,97,31,'#14243a','#7f9bb2',3,5)
 for xx in [309,327,345,363]:out+=rect(xx,441,9,12,'#81e3e1','#214c67',1,2)
 # mechanical title cartouche
 out+=path('M195 60 L220 51 L460 51 L485 69 L476 105 L204 105Z','#172846','url(#metal)',4)
 out+=path('M219 116 L461 116','none','#c58269',2)+path('M245 532 L280 518 L399 518 L432 532','none','#7592ae',3)
 return svg(out,defs=defs)

for name,fn in [('last_orders',pub),('empire_estates',empire),('time_shift',timeshift)]:
 (A/'cabinets'/f'{name}.svg').write_text(fn())

# Reel symbols: crisp two-tone bold silhouettes, optical weight tailored for phone reels.
def sym(body,defs=''): return svg(body,128,128,defs)
cherry=path('M42 65 Q52 24 83 21 Q71 36 78 67','none','#246536',7)+path('M59 36 Q34 12 24 32 Q40 47 59 36Z','#5f9c35','#285c31',3)+circle(40,83,24,'url(#red)','#572127',4)+circle(84,83,25,'url(#red)','#572127',4)+path('M25 78 Q27 67 38 65 M69 76 Q74 66 84 66','none','#ffd5a1',5)
lemon=path('M19 81 Q11 48 47 31 Q79 13 103 42 L111 46 L106 57 Q108 90 76 101 Q44 115 25 89Z','#edc336','#92752b',4)+path('M29 69 Q33 43 62 37','none','#fff4a1',7)+path('M78 26 Q84 10 108 17 Q104 33 86 35Z','#4b8b42','#386636',3)
bell=path('M55 26 Q54 12 66 12 Q79 12 77 26','none','#71521e',5)+path('M27 91 Q40 78 39 57 Q38 27 65 25 Q93 27 92 57 Q91 78 105 91Z','url(#gold)','#71521e',4)+ellipse(66,93,39,10,'#ad7627','#71521e',4)+circle(66,102,10,'url(#gold)','#71521e',3)+path('M49 61 Q47 41 62 36','none','#fff5b6',6)
# BAR lettering rendered as original polygon paths to avoid SVG fonts.
bar=rect(12,34,104,63,'#183d45','#19322e',4,9)+rect(17,39,94,53,'none','#f7d18b',2,5)
bar+=path('M27 49 L38 49 Q49 49 47 60 Q46 64 42 65 Q51 66 49 77 Q48 84 37 84 L27 84Z M34 55 L34 62 L38 62 Q42 62 41 58 Q41 55 38 55Z M34 69 L34 78 L38 78 Q44 78 42 73 Q42 69 38 69Z','#fbe6b5',other='fill-rule="evenodd"')
bar+=path('M53 84 L62 49 L70 49 L80 84 L72 84 L70 76 L61 76 L59 84Z M63 69 L68 69 L66 57Z','#fbe6b5',other='fill-rule="evenodd"')
bar+=path('M84 84 L84 49 L95 49 Q109 49 105 66 Q104 70 100 71 L108 84 L99 84 L92 72 L91 72 L91 84Z M91 56 L91 65 L95 65 Q100 64 99 59 Q99 56 95 56Z','#fbe6b5',other='fill-rule="evenodd"')
seven=path('M25 25 L105 25 L105 42 Q76 68 71 105 L41 105 Q49 70 77 46 L25 46Z','#e43933','#652331',5)+path('M33 32 L96 32 L96 38 M57 91 L51 98','none','#ffd88d',4)
beer=path('M31 44 L86 44 L82 106 L35 106Z','url(#gold)','#67401f',4)+path('M87 50 Q116 41 114 69 Q113 91 85 87','none','#845921',8)+path('M90 52 Q109 47 108 67 Q108 80 87 80','none','#efc77a',4)+path('M42 57 L44 92 M57 56 L58 92 M72 57 L70 92','none','#f7dd8a',5)
for xx,yy,rr in [(38,39,12),(51,31,14),(69,33,14),(84,39,12)]:beer+=circle(xx,yy,rr,'#fff2d1','#b99f75',2)
property_sym=path('M15 53 L64 16 L112 53Z','url(#gold)','#455b46',4)+rect(24,53,80,53,'url(#cream)','#455b46',4)+rect(18,102,92,9,'url(#gold)','#455b46',3)
for xx in [33,57,81]: property_sym+=rect(xx,62,13,35,'url(#green)','#455b46',2)
property_sym+=circle(64,40,7,'#35765b','#776539',2)
clock= circle(64,65,47,'url(#metal)','#263752',4)+circle(64,65,37,'#233954','#81cbd8',3)
for i in range(12):
 a=i*math.tau/12;clock+=circle(64+29*math.sin(a),65-29*math.cos(a),2.5,'#f1d795')
clock+=path('M64 65 L48 46 M64 65 L85 55','none','#f6dfaa',5)+circle(64,65,5,'#e89365')+rect(53,10,22,10,'url(#gold)','#263752',3,2)
lucky_bell=bell+path('M65 23 Q43 7 36 19 Q41 31 61 28 L54 43 L64 38 L68 44 L72 29 Q91 32 95 20 Q84 9 70 23Z','url(#red)','#813029',2)+circle(67,25,5,'#f6d083','#815026',2)
for cx,cy in [(58,64),(73,64),(65,54)]:lucky_bell+=circle(cx,cy,7,'#33734b','#1b5037',1.5)
lucky_bell+=path('M65 65 L65 80','none','#245d3b',3)
for name,body in [('cherry',cherry),('lemon',lemon),('bell',bell),('bar',bar),('seven',seven),('last_orders_special',lucky_bell),('tankard',beer),('empire_estates_special',property_sym),('time_shift_special',clock),('special',star(64,64,48,'#e5b653')+star(64,64,29,'#fff0c1'))]:
 (A/'symbols'/f'{name}.svg').write_text(sym(body))
# Application icon is a cabinet with three original fruit symbols.
icon=rect(0,0,128,128,'#152b31',rx=26)+rect(18,11,92,106,'#294e45','#d7b36a',4,11)+path('M25 20 L103 20 L100 57 L28 57Z','#b44f32','#e4bc65',3)+star(64,39,17,'#f5d77b')+rect(27,64,74,29,'#fff1ce','#152b31',3,3)
for xx in [34,57,80]:icon+=rect(xx,101,15,7,'#d89e43','#182b2b',1,2)
icon+=group(cherry,'translate(27 62) scale(.24)')+group(bell,'translate(50 62) scale(.24)')+group(seven,'translate(74 62) scale(.24)')
(A/'icon.svg').write_text(sym(icon))

# Original generated PCM: deterministic synthesis, never recordings or imported samples.
SR=22050
rng=random.Random(1998)
def write_sound(name,duration,fn,volume=.8):
 n=int(SR*duration);data=bytearray()
 for i in range(n):
  t=i/SR;v=max(-1,min(1,fn(t,i,n)*volume));data.extend(struct.pack('<h',int(v*32767)))
 with wave.open(str(A/'audio'/f'{name}.wav'),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR);w.writeframes(data)
def env(t,d,a=.008):return min(1,t/a)*max(0,1-t/d)**1.7
def sine(f,t):return math.sin(math.tau*f*t)
def tone_seq(notes,step,gate=.75,decay=2):
 def f(t,i,n):
  ix=min(int(t/step),len(notes)-1);local=t-ix*step;dur=step*gate
  return (sine(notes[ix],local)+.22*sine(notes[ix]*2,local))*.6*env(local,dur) if local<dur else 0
 return f
write_sound('click',.075,lambda t,i,n:(rng.uniform(-1,1)*.6+sine(920,t)*.3)*math.exp(-t*70),.55)
write_sound('stop',.15,lambda t,i,n:(rng.uniform(-1,1)*.8+sine(130,t)*.4)*math.exp(-t*35)+sine(1000,t)*.15*math.exp(-t*70),.65)
write_sound('spin',1.25,lambda t,i,n: (rng.uniform(-1,1)*.25+sine(70,t)*.12)*(0.6+.4*max(0,sine(26,t)))*min(1,t/.03)*min(1,(1.25-t)/.1),.45)
write_sound('credit',.44,tone_seq([1320,1760,2200],.145),.45)
write_sound('move',.11,tone_seq([659],.11),.35)
write_sound('win',1.05,tone_seq([523.25,659.25,783.99,1046.5,1318.5],.21),.55)
write_sound('feature',1.2,tone_seq([392,523.25,493.88,659.25,783.99,1046.5],.2),.55)
write_sound('collect',.72,tone_seq([880,1174.66,1567.98,2093],.18),.4)
write_sound('lose',.55,tone_seq([330,261.6,196],.18),.4)
write_sound('jackpot',2.4,tone_seq([523.25,659.25,783.99,1046.5,783.99,1046.5,1174.66,1318.51,1046.5,1318.51,1567.98,2093],.2),.55)
for name,freqs in [('last_orders',[130.813,164.814,195.998]),('empire_estates',[110,138.591,164.814]),('time_shift',[98,146.832,196])]:
 # Integral-period tones ensure seamless four-second loops. Very quiet ambient bed.
 fs=[round(f*4)/4 for f in freqs]
 write_sound('ambient_'+name,4,lambda t,i,n,fs=fs:sum(sine(f,t)*(.55+.2*sine(.25,t+j)) for j,f in enumerate(fs))*.035,1)

font_sources={'display.ttf':'/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf','body.ttf':'/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf','bold.ttf':'/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf','mono.ttf':'/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'}
for name,src in font_sources.items():
 if Path(src).exists(): shutil.copyfile(src,A/'fonts'/name)
license=Path('/usr/share/doc/fonts-dejavu-core/copyright')
if license.exists():shutil.copyfile(license,A/'fonts'/'LICENSE-DejaVu.txt')
print('Generated 3 illustrated cabinet glasses, 10 symbols, icon, 13 PCM sounds and 4 licensed fonts.')
