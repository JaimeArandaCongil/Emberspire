# F2-PULIDO-C · muro del tiro: desviación de luminancia y contraste (gris a 1/4, como test_da.thumbnail_separation).
# Uso: python3 medir_tiro.py <dir_salas_horneadas> <dir_capturas>
import sys, json
from PIL import Image
import numpy as np
RD, SD = sys.argv[1], sys.argv[2]
CD = '/home/user/Emberspire/assets/baked/creatures'
def L(a):  # luminancia 0–255 como PIL «L»
    a = a.astype(float)
    return 0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]
def lum01(a):
    a = a.astype(float) / 255
    return 0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]
def layer(name, m):
    return np.asarray(Image.open(f'{RD}/{name}_prev.png').convert('RGBA'))[:, m:m + 640]
def room(kind, v, c):
    out = np.zeros((360, 640, 4), np.uint8)
    for a in [layer('sky', 4), layer('far_' + kind, 4), layer(f'mid_{kind}_v{v}_c{c}', 0), layer('fore', 8)]:
        out = np.where(a[..., 3:4] > 127, a, out)
    return out
def dil(m, r=1):
    o = m.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            o |= np.roll(np.roll(m, dy, 0), dx, 1)
    return o
def fill_holes(m):  # fuera = lo que se alcanza desde el borde sin cruzar la máscara
    out = np.zeros_like(m); out[0, :] = out[-1, :] = True; out[:, 0] = out[:, -1] = True; out &= ~m
    while True:
        n = dil(out) & ~m
        if (n == out).all():
            return ~out
        out = n
def thumb(g, f=4):
    h, w = g.shape[0] // f, g.shape[1] // f
    return g[:h * f, :w * f].reshape(h, f, w, f).mean((1, 3))
def sep(lumimg, mask):
    t = thumb(lumimg); fig = thumb(mask.astype(float)) > 0.5
    ring = np.zeros_like(fig)
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            ring |= np.roll(np.roll(fig, dy, 0), dx, 1)
    ring &= ~fig
    return abs(t[fig].mean() - t[ring].mean())
# Zonas en px de arte (x0, y0, x1, y1), exclusivas.
Z = {'jefe (14: bbox sobre la baranda)': (333, 82, 573, 206), 'cuerpo jefe (sin grúa)': (333, 132, 573, 206),
     'élite @466': (420, 140, 512, 206), 'flanco izq.': (284, 60, 332, 200), 'flanco der.': (574, 80, 598, 200),
     'cúpula': (300, 40, 580, 82)}
res = {'salas': {}, 'contraste_salas': {}, 'capturas': {}}
for kind, vs in (('flue', range(2)), ('normal', range(4))):
    for v in vs:
        for c in range(2):
            g = L(room(kind, v, c))
            res['salas'][f'{kind}_v{v}_c{c}'] = {k: round(float(g[y0:y1, x0:x1].std()), 2) for k, (x0, y0, x1, y1) in Z.items()}
def frames(cid):
    js = json.load(open(f'{CD}/{cid.split("@")[0]}.json'))
    im = np.asarray(Image.open(f'{CD}/{cid}_prev.png').convert('RGBA'))
    W, H = js['size']; ox, oy = js['origin']; n = js['anims']['idle']['frames']; r = js['anims']['idle']['row']
    fs = [im[r * H:(r + 1) * H, k * W:(k + 1) * W] for k in range(n)]
    ys, xs = np.nonzero(fs[0][..., 3] > 127)
    return fs, (xs.min() + xs.max() + 1) / 2, oy
rooms = [room('flue', v, c) for v in range(2) for c in range(2)]
for cid, slots in (('hollow_knight', [466]), ('candle_mite', [312, 466, 591])):
    fs, cx, oy = frames(cid)
    for sx in slots:
        best = 9
        for R in rooms:
            for f in fs:
                sc = R.copy(); mk = np.zeros((360, 640), bool)
                x0 = int(round(sx - cx)); y0 = 264 - oy; h, w = f.shape[:2]
                ya, yb, xa, xb = max(0, y0), min(360, y0 + h), max(0, x0), min(640, x0 + w)
                sub = f[ya - y0:yb - y0, xa - x0:xb - x0]; al = sub[..., 3:4] > 127
                sc[ya:yb, xa:xb] = np.where(al, sub, sc[ya:yb, xa:xb]); mk[ya:yb, xa:xb] = al[..., 0]
                best = min(best, sep(lum01(sc), mk))
        res['contraste_salas'][f'{cid}@{sx}'] = round(best, 3)
# Capturas: máscara del jefe y de los ácaros = contorno + colores ausentes del fondo (como medir.py C9), con huecos rellenos.
# Se calcula sobre la captura «antes» (MASK_DIR) para que antes y después usen la misma máscara.
MD = sys.argv[3] if len(sys.argv) > 3 else SD
def art(d, n):
    return np.asarray(Image.open(f'{d}/{n}.png').convert('RGB'))[::2, ::2]
def masks(am):
    k = (am[..., 0].astype(int) << 16) | (am[..., 1].astype(int) << 8) | am[..., 2]
    ref = np.unique(np.concatenate([k[40:264, 200:290].ravel(), k[40:264, 604:640].ravel()]))
    raw = ~np.isin(k, ref) | (k == 0x0B080E)
    out = {}
    for nm, (x0, y0, x1, y1) in {'jefe': (333, 82, 573, 264), 'acaro_izq': (300, 235, 326, 265), 'acaro_der': (579, 235, 605, 265)}.items():
        m = np.zeros(k.shape, bool); m[y0:y1, x0:x1] = raw[y0:y1, x0:x1]
        m = dil(m, 1); m[y1 - 2:y1, x0:x1] = True
        m = fill_holes(m); m[y1 - 2:y1] = False
        out[nm] = m
    return out
# Medida determinista: las figuras de la captura «antes» (MASK_DIR, con su luz de juego) pegadas sobre las 4 salas de tiro
# (vista previa). Aísla el cambio de la sala: la pose del jefe varía entre recorridos.
res['pegado_sobre_salas'] = {}
for n in ('14_boss_summon', '14a_summon_reveal'):
    am = art(MD, n); ms = masks(am)
    zb = np.zeros(ms['jefe'].shape, bool); zb[82:206, 333:573] = True
    zc = np.zeros_like(zb); zc[132:206, 333:573] = True
    d = {}
    for v in range(2):
        for c in range(2):
            R = room('flue', v, c)[..., :3].copy()
            e = {}
            for nm, m in ms.items():
                sc = R.copy(); sc[m] = am[m]
                e[f'sep_{nm}'] = round(float(sep(lum01(sc), m)), 4)
            g = L(R)
            e['desv_sala_tras_jefe (bbox, sin figura)'] = round(float(g[zb & ~dil(ms['jefe'], 2)].std()), 2)
            e['desv_sala_tras_cuerpo (y 132-205, sin figura)'] = round(float(g[zc & ~dil(ms['jefe'], 2)].std()), 2)
            d[f'v{v}_c{c}'] = e
    res['pegado_sobre_salas'][n] = d
for n in ('14_boss_summon', '14a_summon_reveal'):
    a, am = art(SD, n), art(SD, n)
    k = (am[..., 0].astype(int) << 16) | (am[..., 1].astype(int) << 8) | am[..., 2]
    ref = np.unique(np.concatenate([k[40:264, 200:290].ravel(), k[40:264, 604:640].ravel()]))
    raw = ~np.isin(k, ref) | (k == 0x0B080E)
    d = {}
    for nm, (x0, y0, x1, y1) in {'jefe': (333, 82, 573, 264), 'acaro_izq': (300, 235, 326, 265), 'acaro_der': (579, 235, 605, 265)}.items():
        m = np.zeros(k.shape, bool); m[y0:y1, x0:x1] = raw[y0:y1, x0:x1]
        m = dil(m, 1); m[y1 - 2:y1, x0:x1] = True  # cierra el suelo entre las patas
        m = fill_holes(m); m[y1 - 2:y1] = False
        d[f'sep_{nm}'] = round(float(sep(lum01(a), m)), 4)
        if nm == 'jefe':
            mj = dil(m, 2)
    g = L(a)
    zb = np.zeros(k.shape, bool); zb[82:206, 333:573] = True
    d['desv_fondo_tras_jefe (art 333-572 x 82-205, sin el jefe)'] = round(float(g[zb & ~mj].std()), 2)
    d['px_fondo_visibles'] = int((zb & ~mj).sum())
    d['desv_jefe_px666-1146x164-412'] = round(float(g[82:206, 333:573].std()), 2)
    d['desv_cuerpo_px666-1146x264-412'] = round(float(g[132:206, 333:573].std()), 2)
    g2 = np.asarray(Image.open(f'{SD}/{n}.png').convert('L')).astype(float)
    d['desv_px_cuerpo'] = round(float(g2[264:412, 666:1146].std()), 2)
    res['capturas'][n] = d
g7 = np.asarray(Image.open(f'{SD}/07_combat.png').convert('L')).astype(float)
res['capturas']['07_C19'] = round(float(g7[130:250, 780:1000].std()), 2)
print(json.dumps(res, ensure_ascii=False, indent=1))
