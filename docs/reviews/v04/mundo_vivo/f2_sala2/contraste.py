# Contraste mínimo de criaturas contra las salas (gris a 1/4, como test_da.thumbnail_separation).
import sys, json, glob
from PIL import Image; import numpy as np
RD = sys.argv[1]; CD = '/home/user/Emberspire/assets/baked/creatures'
def lum(a):
    a = a.astype(float) / 255
    return (0.2126*a[...,0] + 0.7152*a[...,1] + 0.0722*a[...,2]) * a[...,3]
def layer(name, m):
    a = np.asarray(Image.open(f'{RD}/{name}_prev.png').convert('RGBA'))
    return a[:, m:m+640]
def room(kind, v, c):
    out = np.zeros((360, 640, 4), np.uint8)
    for a in [layer('sky', 4), layer('far_' + kind, 4), layer(f'mid_{kind}_v{v}_c{c}', 0), layer('fore', 8)]:
        al = a[..., 3:4] > 127
        out = np.where(al, a, out)
    return out
def thumb(g, f=4):
    h, w = g.shape[0] // f, g.shape[1] // f
    return g[:h*f, :w*f].reshape(h, f, w, f).mean((1, 3))
def sep(scene, mask):
    t = thumb(lum(scene)); m = thumb(mask.astype(float))
    fig = m > 0.5
    ring = np.zeros_like(fig)
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            ring |= np.roll(np.roll(fig, dy, 0), dx, 1)
    ring &= ~fig
    return abs(t[fig].mean() - t[ring].mean())
CRE = {'candle_mite': [350, 396, 460, 540, 572], 'ash_slime': [396, 466, 540], 'cinder_bat': [350, 396, 466, 572],
       'soot_golem@sooty': [396, 466], 'ember_magpie': [396, 466], 'flame_moth': [396, 540]}
rooms = {'normal': [room('normal', v, c) for v in range(4) for c in range(2)],
         'flue': [room('flue', v, c) for v in range(2) for c in range(2)]}
def frames(cid):
    js = json.load(open(f'{CD}/{cid.split("@")[0]}.json')) if '@' not in cid else json.load(open(f'{CD}/{cid.split("@")[0]}.json'))
    im = np.asarray(Image.open(f'{CD}/{cid}_prev.png').convert('RGBA'))
    W, H = js['size']; ox, oy = js['origin']; n = js['anims']['idle']['frames']; r = js['anims']['idle']['row']
    fs = [im[r*H:(r+1)*H, k*W:(k+1)*W] for k in range(n)]
    ys, xs = np.nonzero(fs[0][..., 3] > 127)
    cx = (xs.min() + xs.max() + 1) / 2
    return fs, cx, oy
res = {}
for cid, slots in list(CRE.items()) + [('hollow_knight', [466])]:
    fs, cx, oy = frames(cid)
    kind = 'flue' if cid == 'hollow_knight' else 'normal'
    for sx in slots:
        best = 9
        for R in rooms[kind]:
            for f in fs:
                sc = R.copy(); mk = np.zeros((360, 640), bool)
                x0 = int(round(sx - cx)); y0 = 264 - oy
                h, w = f.shape[:2]
                ya, yb = max(0, y0), min(360, y0 + h); xa, xb = max(0, x0), min(640, x0 + w)
                sub = f[ya - y0:yb - y0, xa - x0:xb - x0]
                al = sub[..., 3:4] > 127
                sc[ya:yb, xa:xb] = np.where(al, sub, sc[ya:yb, xa:xb])
                mk[ya:yb, xa:xb] = al[..., 0]
                best = min(best, sep(sc, mk))
        res[f'{cid}@{sx}'] = round(best, 3)
print(json.dumps(res))
