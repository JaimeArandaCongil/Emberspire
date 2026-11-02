"""F2-REV2 (copia adaptada de F2-BASE): mediciones reproducibles sobre las capturas del recorrido `tests/smoke.tscn`.

Uso:  python3 -I docs/reviews/v04/director/f2_rev2/medir.py [carpeta_capturas] [salida.json]
Por defecto lee `screenshots/*.png` y escribe `mediciones.json` junto a este script.
Sólo PIL + numpy. No modifica nada fuera de su salida.

Ejes (ver revision.md):
 1. rejilla   bloques 2×2 alineados (fase 0,0) no uniformes; zonas donde se rompe y su clase.
 2. paleta    colores únicos, % de píxeles fuera de `Palette`, mezclas de dos colores de paleta, ajenos más frecuentes.
 3. legibilidad  contraste WCAG texto/fondo en zonas fijas de 07, 08, 09 y 13; altura real de las cifras.
 4. disposición  bboxes de luchadores (en px de mundo 640×360) en 07, 14, 16, 18 contra docs/DECISIONES.md.
Coordenadas: `px` = píxeles de pantalla 1280×720; `art` = píxeles de mundo 640×360 (= px // 2).
"""
from __future__ import annotations

import hashlib
import json
import re
import sys
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
SHOTS = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "screenshots"
OUT = Path(sys.argv[2]) if len(sys.argv) > 2 else HERE / "mediciones.json"

# Capturas con arte legado (actos 2 y 3, sin luz): se miden pero no se mezclan en las notas del corte.
LEGADO = {"16_act2_hydra", "17_act3", "18_frost_king"}
# Jefe del acto 1 (en F2-REV2 ya en rig, F2-JEFE); el nombre del conjunto se conserva por comparabilidad.
JEFE_LEGADO = {"14_boss_summon", "14a_summon_reveal"}
COMBATE = {"07_combat", "07b_glow", "08_combat_hover", "09_burn", "09a_block_toss", "09b_burn_flight", "10_swing",
           "10b_enemy_turn", "11_after_enemy_turn", "12_death_dissolve", "14_boss_summon", "14a_summon_reveal",
           "16_act2_hydra", "17_act3", "18_frost_king", "18b_hero_death"}

# Tooltips identificados a mano (bbox px). Única fuente manual del eje 1: la excepción Pavesa ×1 de DECISIONES.md
# cubre «cuerpo de carta y tooltips»; el cuerpo de carta se detecta solo (pergamino), los tooltips no.
TOOLTIPS = {"08_combat_hover": [(520, 436, 760, 482)]}


# ---------------------------------------------------------------- paleta
def leer_paleta() -> tuple[dict[int, list[str]], set[int]]:
    """{color24: [material:paso...]} y el subconjunto de colores de texto/pergamino."""
    src = (ROOT / "scripts/art/palette.gd").read_text(encoding="utf-8")
    pal: dict[int, list[str]] = {}
    ramps = src[src.index("const RAMPS"):src.index("const UI")]
    for m in re.finditer(r'&"(\w+)":\s*\[\[(.*?)\]\s*,\s*\[(.*?)\]\]', ramps, re.S):
        name = m.group(1)
        for frio, grupo in ((0, m.group(2)), (1, m.group(3))):
            for paso, h in enumerate(re.findall(r'"([0-9a-fA-F]{6})"', grupo)):
                pal.setdefault(int(h, 16), []).append(f"{name}{':f' if frio else ''}:{paso}")
    ui = src[src.index("const UI"):src.index("static var")]
    for name, h in re.findall(r'&"(\w+)":\s*Color\("([0-9a-fA-F]{6})"\)', ui):
        pal.setdefault(int(h, 16), []).append(f"UI.{name}")
    h = re.search(r'const OUTLINE := Color\("([0-9a-fA-F]{6})"\)', src).group(1)
    pal.setdefault(int(h, 16), []).append("OUTLINE")
    texto = {c for c, ms in pal.items() if any(t.startswith(("parch", "ink", "UI.", "OUTLINE", "plate", "shadow_ui"))
                                                  for t in ms)}
    return pal, texto


PAL, TEXTO = leer_paleta()
PAL_KEYS = np.array(sorted(PAL), dtype=np.int64)
PERGAMINO = {c for c, ms in PAL.items() if any(t.split(":")[0] in
             ("parch_attack", "parch_skill", "parch_power", "parch_fuel", "parch_status") and not t.endswith(":0")
             for t in ms)}
OUTLINE = 0x0B080E


def clave(a: np.ndarray) -> np.ndarray:
    a = a.astype(np.int64)
    return (a[..., 0] << 16) | (a[..., 1] << 8) | a[..., 2]


def hexs(k: int) -> str:
    return f"{k:06x}"


def rgb(k) -> np.ndarray:
    k = np.asarray(k, dtype=np.int64)
    return np.stack([(k >> 16) & 255, (k >> 8) & 255, k & 255], -1).astype(np.float64)


def en_paleta(k: np.ndarray) -> np.ndarray:
    return np.isin(k, PAL_KEYS)


# ---------------------------------------------------------------- utilidades
def componentes(mask: np.ndarray, min_n: int = 1, celdas: list | None = None) -> list[tuple[int, int, int, int, int]]:
    """Componentes 8-conexas: lista de (x0, y0, x1, y1, n) con x1/y1 inclusivos. Si `celdas` es una lista,
    añade en ella la lista de (y, x) de cada componente."""
    h, w = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    out = []
    ys, xs = np.nonzero(mask)
    for y, x in zip(ys.tolist(), xs.tolist()):
        if seen[y, x]:
            continue
        q = deque([(y, x)])
        seen[y, x] = True
        x0 = x1 = x
        y0 = y1 = y
        n = 0
        miembros = []
        while q:
            cy, cx = q.popleft()
            n += 1
            miembros.append((cy, cx))
            x0, x1, y0, y1 = min(x0, cx), max(x1, cx), min(y0, cy), max(y1, cy)
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = cy + dy, cx + dx
                    if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        q.append((ny, nx))
        if n >= min_n:
            out.append((x0, y0, x1, y1, n))
            if celdas is not None:
                celdas.append(miembros)
    return out


def dilatar(mask: np.ndarray, r: int) -> np.ndarray:
    out = mask.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            out |= np.roll(np.roll(mask, dy, 0), dx, 1)
    return out


def no_uniforme(k: np.ndarray, fy: int, fx: int) -> np.ndarray:
    """Máscara (bloques) de 2×2 con píxeles distintos, empezando en la fase (fy, fx)."""
    h, w = k.shape
    b = k[fy:fy + (h - fy) // 2 * 2, fx:fx + (w - fx) // 2 * 2]
    a, bb, c, d = b[0::2, 0::2], b[0::2, 1::2], b[1::2, 0::2], b[1::2, 1::2]
    return (a != bb) | (a != c) | (a != d)


def zona_layout(x0, y0, x1, y1) -> str:
    cy = (y0 + y1) / 2
    if cy < 32:
        return "HUD superior con rótulo de piso (y art 0–15)"
    if cy < 90:
        return "banda de intención de jefe (y art 22–44)"
    if cy < 118:
        return "barra de ayuda (y art 47–57)"
    if cy >= 584:
        return "mano y HUD inferior (y art ≥ 292)"
    if cy >= 526:
        return "placas de PV (y art 264–292)"
    return "mundo"


# ---------------------------------------------------------------- eje 1: rejilla
def medir_rejilla(nombre: str, k: np.ndarray) -> dict:
    nu = no_uniforme(k, 0, 0)
    alt = {f: no_uniforme(k, *f) for f in ((0, 1), (1, 0), (1, 1))}
    # cajas de pergamino (cuerpo de carta) en px
    perg = np.isin(k[::2, ::2], list(PERGAMINO))
    cajas = [(x0 * 2, y0 * 2, x1 * 2 + 1, y1 * 2 + 1) for x0, y0, x1, y1, n in componentes(dilatar(perg, 1), 200)
             if (x1 - x0) >= 30 and (y1 - y0) >= 14]
    tips = TOOLTIPS.get(nombre, [])
    # celdas de 8×8 bloques (16×16 px)
    hb, wb = nu.shape
    celdas = nu[: hb // 8 * 8, : wb // 8 * 8].reshape(hb // 8, 8, wb // 8, 8).sum((1, 3))
    zonas = []
    pal_ok = en_paleta(k)
    miembros: list = []
    comps = componentes(celdas >= 3, 1, miembros)
    for (cx0, cy0, cx1, cy1, _), mc in zip(comps, miembros):
        cm = np.zeros(celdas.shape, bool)
        for cy, cx in mc:
            cm[cy, cx] = True
        propio = np.zeros(nu.shape, bool)
        propio[: hb // 8 * 8, : wb // 8 * 8] = np.repeat(np.repeat(cm, 8, 0), 8, 1)
        propio &= nu
        sub = propio[cy0 * 8:(cy1 + 1) * 8, cx0 * 8:(cx1 + 1) * 8]
        ys, xs = np.nonzero(sub)
        if len(ys) < 12:
            continue
        by0, bx0 = cy0 * 8 + ys.min(), cx0 * 8 + xs.min()
        by1, bx1 = cy0 * 8 + ys.max(), cx0 * 8 + xs.max()
        bb = (int(bx0 * 2), int(by0 * 2), int(bx1 * 2 + 1), int(by1 * 2 + 1))
        area = (by1 - by0 + 1) * (bx1 - bx0 + 1)
        tasa = float(nu[by0:by1 + 1, bx0:bx1 + 1].mean())
        # ¿es arte ×2 desplazado medio píxel de rejilla?
        tasas_alt = {f"{f[0]},{f[1]}": round(float(m[by0:by1 + 1, bx0:bx1 + 1].mean()), 3) for f, m in alt.items()}
        mejor = min(tasas_alt.values())
        # píxeles de los bloques rotos
        blk = np.zeros(k.shape, bool)
        blk[bb[1]:bb[3] + 1, bb[0]:bb[2] + 1] = np.repeat(np.repeat(propio[by0:by1 + 1, bx0:bx1 + 1], 2, 0), 2, 1)
        px = k[blk]
        f_pal = float(pal_ok[blk].mean())
        f_txt = float(np.isin(px, list(TEXTO)).mean())
        ccx, ccy = (bb[0] + bb[2]) / 2, (bb[1] + bb[3]) / 2
        en_carta = any(c[0] <= ccx <= c[2] and c[1] <= ccy <= c[3] for c in cajas)
        en_tip = any(c[0] <= ccx <= c[2] and c[1] <= ccy <= c[3] for c in tips)
        if mejor < 0.5 * tasa and tasa > 0.05:
            clase = "arte ×2 desfasado 1 px"
        elif f_pal < 0.5:
            clase = "mezcla/filtrado (colores fuera de paleta)"
        elif en_carta:
            clase = "texto ×1 en cuerpo de carta (Pavesa permitida)"
        elif en_tip:
            clase = "texto ×1 en tooltip (Pavesa permitida)"
        else:
            clase = "detalle ×1 en paleta (texto Pavesa fuera de excepción o arte ×1)"
        zonas.append({"bbox_px": bb, "bloques_rotos": int(len(ys)), "tasa_en_bbox": round(tasa, 3),
                      "tasa_otras_fases": tasas_alt, "frac_en_paleta": round(f_pal, 3),
                      "frac_colores_texto": round(f_txt, 3), "zona": zona_layout(*bb), "clase": clase})
    zonas.sort(key=lambda z: -z["bloques_rotos"])
    tot = nu.size
    por_clase: dict[str, int] = {}
    for z in zonas:
        por_clase[z["clase"]] = por_clase.get(z["clase"], 0) + z["bloques_rotos"]
    return {"pct_bloques_2x2_no_uniformes": round(100 * float(nu.mean()), 3),
            "bloques_rotos": int(nu.sum()), "bloques_totales": int(tot),
            "pct_por_clase": {c: round(100 * n / tot, 3) for c, n in por_clase.items()},
            "pct_fuera_de_excepcion": round(100 * sum(n for c, n in por_clase.items() if "permitida" not in c) / tot, 3),
            "cajas_pergamino_px": cajas, "zonas": zonas[:25], "zonas_total": len(zonas)}


# ---------------------------------------------------------------- eje 2: paleta
def mezclas(fk: np.ndarray, base: np.ndarray, tol: float = 1.0) -> np.ndarray:
    """True si cada color fk está (±tol por canal, redondeo de 8 bits) sobre el segmento entre dos colores de `base`."""
    F = rgb(fk)
    B = rgb(base)
    i, j = np.triu_indices(len(B), 1)
    P, Q = B[i], B[j]
    D = P - Q
    dd = (D * D).sum(1)
    dd[dd == 0] = 1
    ok = np.zeros(len(F), bool)
    for s in range(0, len(F), 1500):
        f = F[s:s + 1500, None, :]
        t = np.clip(((f - Q[None]) * D[None]).sum(2) / dd[None], 0, 1)
        r = np.abs(f - (Q[None] + t[..., None] * D[None])).max(2)
        ok[s:s + 1500] = (r <= tol).any(1)
    return ok


def medir_paleta(k: np.ndarray) -> dict:
    u, inv, cnt = np.unique(k.ravel(), return_inverse=True, return_counts=True)
    dentro = en_paleta(u)
    total = k.size
    fu = u[~dentro]
    # 1) redondeo: a ≤ 2 por canal de un color de paleta
    F = rgb(fu)
    Pk = rgb(PAL_KEYS)
    cerca = np.zeros(len(fu), bool)
    for s in range(0, len(fu), 2000):
        cerca[s:s + 2000] = (np.abs(F[s:s + 2000, None] - Pk[None]).max(2) <= 2).any(1)
    # 2) mezcla alfa entre dos colores de paleta presentes en la captura (los 48 más frecuentes) o con negro
    pres = u[dentro][np.argsort(-cnt[dentro])][:48]
    base = np.concatenate([pres, [0x000000]])
    mez = np.zeros(len(fu), bool)
    resto = ~cerca
    if resto.any():
        mez[resto] = mezclas(fu[resto], base)
    ajeno = ~cerca & ~mez
    fc = cnt[~dentro]
    res = {"colores_unicos": int(len(u)), "colores_paleta_usados": int(dentro.sum()),
           "pct_px_en_paleta": round(100 * cnt[dentro].sum() / total, 3),
           "pct_px_redondeo": round(100 * fc[cerca].sum() / total, 3),
           "pct_px_mezcla_dos_paleta": round(100 * fc[mez].sum() / total, 3),
           "pct_px_ajenos": round(100 * fc[ajeno].sum() / total, 3),
           "colores_ajenos": int(ajeno.sum())}
    # ajenos más frecuentes con su bbox
    top = []
    aj_k, aj_c = fu[ajeno], fc[ajeno]
    for idx in np.argsort(-aj_c)[:10]:
        ys, xs = np.nonzero(k == aj_k[idx])
        top.append({"hex": hexs(int(aj_k[idx])), "px": int(aj_c[idx]),
                    "bbox_px": [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())],
                    "centro_px": [int(np.median(xs)), int(np.median(ys))]})
    res["ajenos_top"] = top
    mz = []
    mz_k, mz_c = fu[mez], fc[mez]
    for idx in np.argsort(-mz_c)[:6]:
        ys, xs = np.nonzero(k == mz_k[idx])
        mz.append({"hex": hexs(int(mz_k[idx])), "px": int(mz_c[idx]),
                   "bbox_px": [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())],
                   "centro_px": [int(np.median(xs)), int(np.median(ys))]})
    res["mezclas_top"] = mz
    # zonas con densidad de ajenos ≥ 25 % en celdas de 32×32 px
    m = np.isin(k, aj_k)
    h, w = m.shape
    cel = m[: h // 32 * 32, : w // 32 * 32].reshape(h // 32, 32, w // 32, 32).mean((1, 3))
    zs = []
    for x0, y0, x1, y1, n in componentes(cel >= 0.25):
        zs.append({"bbox_px": [x0 * 32, y0 * 32, x1 * 32 + 31, y1 * 32 + 31], "celdas": n,
                   "pct_ajenos": round(100 * float(m[y0 * 32:(y1 + 1) * 32, x0 * 32:(x1 + 1) * 32].mean()), 1)})
    res["zonas_ajenos"] = sorted(zs, key=lambda z: -z["celdas"])[:8]
    return res


# ---------------------------------------------------------------- eje 3: legibilidad
def lum(c: np.ndarray) -> float:
    c = c / 255.0
    c = np.where(c <= 0.03928, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return float(0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2])


def wcag(a: int, b: int) -> float:
    la, lb = lum(rgb(a)), lum(rgb(b))
    hi, lo = max(la, lb), min(la, lb)
    return round((hi + 0.05) / (lo + 0.05), 2)


# Zonas de texto fijadas a mano sobre 07 (px). Mismo layout en 08/09; 13 y la carta en mano de 08 aparte.
# F2-REV2: actualizadas a la disposición nueva (rótulo de piso en la barra superior, barra de ayuda en px y 94–112,
# placas de PV en px y 530–552, mano a paso 162 con la 1.ª carta en px x 230).
ZONAS_HUD = {
    "ascuas_540K (Fragua)": (28, 2, 74, 22),
    "ascuas_por_s (Mini)": (138, 6, 200, 20),
    "piso_titulo (Fragua)": (462, 3, 588, 24),
    "piso_subtitulo (Mini)": (590, 6, 818, 24),
    "contador_superior_12 (Mini)": (898, 4, 990, 24),
    "barra_ayuda (Mini)": (254, 94, 1026, 112),
    "pv_heroina 86/86": (290, 530, 360, 552),
    "bloqueo_escudo": (216, 526, 244, 556),
    "pv_enemigo_1": (670, 530, 730, 552),
    "pv_enemigo_2": (890, 530, 950, 552),
    "pv_enemigo_3": (1112, 530, 1172, 552),
    "quemas_etiqueta (Mini)": (8, 538, 92, 558),
    "energia 3/3": (50, 592, 92, 620),
    "carta_nombre_golpe": (282, 600, 342, 622),
    "carta_nombre_tajo": (746, 600, 850, 622),
    "fin_de_turno": (1146, 592, 1264, 618),
    "robo_etiqueta (Mini)": (50, 664, 92, 678),
    "robo_8": (48, 680, 72, 702),
    "descarte_etiqueta (Mini)": (1194, 628, 1264, 644),
}
ZONAS_EXTRA = {
    "08_combat_hover": {"carta_hover_titulo": (585, 503, 680, 527), "carta_hover_cuerpo (Pavesa)": (570, 660, 700, 682),
                        "tooltip_quemar (Mini)": (528, 444, 790, 478), "carta_hover_cinta (Mini)": (590, 622, 676, 638)},
    "09_burn": {"nombre_enemigo_hover (Mini)": (640, 511, 760, 530)},
    "10b_enemy_turn": {"intencion_cifra": (678, 286, 724, 310), "flotante_3": (688, 332, 706, 354),
                       "rotulo_mas_hollin (Mini)": (652, 398, 720, 420), "nombre_enemigo (Mini)": (640, 511, 760, 530),
                       "pv_enemigo_1_turno": (670, 530, 730, 552)},
    "13_rewards": {"victoria (Fragua)": (556, 146, 722, 186), "ascuas_combate (Mini)": (422, 204, 858, 222),
                   "titulo_elige": (512, 233, 764, 255), "recompensa_titulo_1 (×1)": (404, 292, 494, 309),
                   "recompensa_titulo_2 (×1)": (590, 292, 682, 309), "recompensa_cuerpo_1 (Pavesa)": (398, 440, 502, 470),
                   "recompensa_cinta_1 (Mini)": (418, 405, 480, 421), "boton_quemar (Mini)": (462, 536, 816, 556)},
}


def medir_texto(k: np.ndarray, bb) -> dict:
    x0, y0, x1, y1 = bb
    z = k[y0:y1, x0:x1]
    u, c = np.unique(z, return_counts=True)
    orden = np.argsort(-c)
    fondo = int(u[orden[0]])
    n = z.size
    cand = [(int(u[i]), int(c[i])) for i in orden[1:] if c[i] >= max(6, 0.02 * n)]
    if not cand:
        return {"bbox_px": bb, "error": "sin candidato de texto"}
    tinta, _ = max(cand, key=lambda t: wcag(t[0], fondo))
    ys, xs = np.nonzero(z == tinta)
    # vecindad inmediata: colores de los píxeles a 1 px de la tinta que no son tinta
    m = z == tinta
    v = dilatar(m, 1) & ~m
    vec_u, vec_c = np.unique(z[v], return_counts=True)
    vec = int(vec_u[np.argmax(vec_c)]) if len(vec_u) else fondo
    return {"bbox_px": list(bb), "fondo": hexs(fondo), "tinta": hexs(tinta),
            "tinta_en_paleta": bool(tinta in PAL), "contraste_tinta_fondo": wcag(tinta, fondo),
            "borde_inmediato": hexs(vec), "contraste_tinta_borde": wcag(tinta, vec),
            "alto_tinta_px": int(ys.max() - ys.min() + 1), "ancho_tinta_px": int(xs.max() - xs.min() + 1),
            "trazo_min_px": trazo_min(m)}


def trazo_min(m: np.ndarray) -> int:
    """Ancho mínimo de trazo horizontal (moda de las rachas) de la tinta: 1 → ×1, 2 → ×2."""
    rachas = []
    for fila in m:
        r = 0
        for v in fila:
            if v:
                r += 1
            elif r:
                rachas.append(r)
                r = 0
        if r:
            rachas.append(r)
    if not rachas:
        return 0
    vals, cnt = np.unique(rachas, return_counts=True)
    return int(vals[np.argmax(cnt)])


# ---------------------------------------------------------------- eje 4: disposición
def medir_disposicion(nombre: str, k: np.ndarray) -> dict:
    a = k[::2, ::2]  # px de mundo
    # Máscara de luchador = contorno universal 0b080e  OR  color que no aparece en la franja de fondo vacía
    # entre heroína y enemigos (art x 200–289, y 40–263) de la misma captura. Sirve también para el arte legado,
    # que no usa ni el contorno ni la paleta. Se limita a y ≥ 170 para el criterio de color (antorchas y ventana).
    partes = [a[40:264, 200:290].ravel(), a[40:264, 604:640].ravel()]
    if nombre in LEGADO:
        partes.append(a[40:130, 124:640].ravel())  # muro superior: en las salas legado no hay luchadores ahí
    ref = np.unique(np.concatenate(partes))
    nuevo = ~np.isin(a, ref)
    jefe = None
    if nombre in LEGADO or nombre in JEFE_LEGADO:
        # Jefe: componente mayor (px) de contorno|color nuevo, sin el corte de y 170, en x 280–603, y 40–263.
        mj = ((a == OUTLINE) | nuevo)
        rj = np.zeros_like(mj)
        rj[40:264, 280:604] = True
        mj &= rj
        cs = componentes(dilatar(mj, 1), 1)
        if cs:
            x0, y0, x1, y1, _ = max(cs, key=lambda c: c[4])
            sub = mj[y0:y1 + 1, x0:x1 + 1]
            ys, xs = np.nonzero(sub)
            bb = [int(x0 + xs.min()), int(y0 + ys.min()), int(x0 + xs.max()), int(y0 + ys.max())]
            jefe = {"bbox_art": bb, "ancho": bb[2] - bb[0] + 1, "alto": bb[3] - bb[1] + 1,
                    "centro_x": (bb[0] + bb[2]) / 2, "pie_y": bb[3]}
    nuevo[:170] = False
    mask = (a == OUTLINE) | nuevo
    reg = np.zeros_like(mask)
    reg[40:265, 124:640] = True
    mask &= reg
    comps = [c for c in componentes(dilatar(mask, 3), 1)]
    # recortar la dilatación: bbox real de la máscara original dentro de cada componente
    out = []
    for x0, y0, x1, y1, _ in comps:
        sub = mask[y0:y1 + 1, x0:x1 + 1]
        n = int(sub.sum())
        if n < 25:
            continue
        ys, xs = np.nonzero(sub)
        bx0, by0, bx1, by1 = x0 + xs.min(), y0 + ys.min(), x0 + xs.max(), y0 + ys.max()
        out.append({"bbox_art": [int(bx0), int(by0), int(bx1), int(by1)], "ancho": int(bx1 - bx0 + 1),
                    "alto": int(by1 - by0 + 1), "centro_x": round((bx0 + bx1) / 2, 1), "pie_y": int(by1), "px": n})
    out.sort(key=lambda c: c["bbox_art"][0])
    # Clasificación: icono de intención (≤ 16×16, aislado) · luchador (toca el suelo, pie ≥ 258) · otro
    for c in out:
        if c["ancho"] <= 16 and c["alto"] <= 16:
            c["tipo"] = "icono"
        elif c["pie_y"] >= 258:
            c["tipo"] = "luchador"
        else:
            c["tipo"] = "otro"
    # Luchadores: unir piezas no conexas (contorno abierto) cuyo intervalo x se solape ≥ 50 % y estén a ≤ 12 px en y
    lu = [c for c in out if c["tipo"] != "icono"]
    cambiado = True
    while cambiado:
        cambiado = False
        for i in range(len(lu)):
            for j in range(i + 1, len(lu)):
                a, b = lu[i]["bbox_art"], lu[j]["bbox_art"]
                ov = min(a[2], b[2]) - max(a[0], b[0]) + 1
                gap = max(a[1], b[1]) - min(a[3], b[3])
                if ov >= 0.5 * min(a[2] - a[0] + 1, b[2] - b[0] + 1) and gap <= 12:
                    bb = [min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3])]
                    lu[i] = {"bbox_art": bb, "ancho": bb[2] - bb[0] + 1, "alto": bb[3] - bb[1] + 1,
                             "centro_x": (bb[0] + bb[2]) / 2, "pie_y": bb[3], "px": lu[i]["px"] + lu[j]["px"],
                             "tipo": "luchador" if bb[3] >= 258 else "otro"}
                    del lu[j]
                    cambiado = True
                    break
            if cambiado:
                break
    luch = sorted([c for c in lu if c["tipo"] == "luchador"], key=lambda c: c["bbox_art"][0])
    iconos = [c for c in out if c["tipo"] == "icono"]
    for l in luch:
        enc = [i for i in iconos if l["bbox_art"][0] <= i["centro_x"] <= l["bbox_art"][2] and i["pie_y"] < l["bbox_art"][1]]
        if enc:
            i = max(enc, key=lambda i: i["pie_y"])
            l["intencion_bbox_art"] = i["bbox_art"]
            l["intencion_hueco_y"] = l["bbox_art"][1] - i["pie_y"] - 1
    return {"luchadores": luch, "jefe_componente_mayor": jefe, "componentes_brutos": out}


# ---------------------------------------------------------------- C8: colores por ilustración
def medir_ilustraciones(k: np.ndarray, cajas: list) -> list:
    """Ventana 68×46 de cada carta con cuerpo visible. Geometría de `scripts/art/cards/frame.gd`: ART (6,17,68,46),
    PARCH (6,70,68,36) → la ventana empieza 53 px de arte por encima del pergamino. Se recorta 3 px por lado para no
    contar el canto de la silueta. Regla vigente (DECISIONES): ≤ 30 colores, ninguno < 10 px salvo 3."""
    a = k[::2, ::2]
    out = []
    for x0, y0, x1, y1 in cajas:
        ax, ay = x0 // 2, y0 // 2 - 53
        if ay < 0 or (x1 - x0 + 1) // 2 < 60:
            continue
        w = a[ay + 3:ay + 46 - 3, ax + 3:ax + 68 - 3]
        u, c = np.unique(w, return_counts=True)
        out.append({"ventana_art": [int(ax), int(ay), 68, 46], "colores": int(len(u)),
                    "colores_menos_10px": int((c < 10).sum()), "pct_en_paleta": round(100 * float(en_paleta(w).mean()), 1),
                    "cumple_regla": bool(len(u) <= 30 and (c < 10).sum() <= 3)})
    return out


# ---------------------------------------------------------------- correcciones C1–C20 medibles en fijo
def rampa(nombre: str) -> set[int]:
    return {c for c, ms in PAL.items() if any(t.split(":")[0] == nombre for t in ms)}


def cargar(nombre: str) -> np.ndarray:
    return clave(np.asarray(Image.open(SHOTS / f"{nombre}.png").convert("RGB")))


def medir_correcciones(res: dict) -> dict:
    out: dict = {}
    emis = list(rampa("fire") | rampa("hot") | rampa("ember_ui"))
    a7, a11 = cargar("07_combat")[::2, ::2], cargar("11_after_enemy_turn")[::2, ::2]
    g = (slice(170, 265), slice(300, 400))  # caja del gólem (centro 350)
    out["C6_quemadura_golem"] = {"caja_art": [300, 170, 399, 264], "px_emisivos_07_sin_estado": int(np.isin(a7[g], emis).sum()),
                                 "px_emisivos_11_con_quemadura": int(np.isin(a11[g], emis).sum()),
                                 "nota": "C6 pide 3–5 lenguas de 3–6 px (≥ ~30 px emisivos nuevos)"}
    # C11: oro que aparece con el Resplandor
    a7b = cargar("07b_glow")[::2, ::2]
    oro = list(rampa("gold"))
    nuevo = np.isin(a7b, oro) & ~np.isin(a7, oro)
    nuevo[264:] = False
    zs = [{"bbox_art": [x0 * 16, y0 * 16, x1 * 16 + 15, y1 * 16 + 15], "px": int(nuevo[y0 * 16:(y1 + 1) * 16, x0 * 16:(x1 + 1) * 16].sum())}
          for x0, y0, x1, y1, n in componentes(nuevo[:256].reshape(16, 16, 40, 16).sum((1, 3)) >= 4)]
    cambiados = (a7b != a7)[:264]
    out["C11_resplandor"] = {"px_art_cambiados_07_a_07b": int(cambiados.sum()), "px_oro_nuevos": int(nuevo.sum()),
                             "zonas_oro": sorted(zs, key=lambda z: -z["px"])[:6]}
    # C18: brasas de muerte (12): componentes emisivos nuevos respecto a 07 en el mundo
    a12 = cargar("12_death_dissolve")[::2, ::2]
    m = np.isin(a12, emis) & (a12 != a7)
    m[:120] = False
    m[262:] = False
    cs = [c for c in componentes(m, 4)]
    tams = sorted(((c[2] - c[0] + 1), (c[3] - c[1] + 1)) for c in cs)
    redondos = [t for t in tams if t[0] >= 4 and t[1] >= 4 and abs(t[0] - t[1]) <= 1]
    out["C18_brasas_muerte"] = {"componentes": len(cs), "tamaños_art_wxh": tams, "de_6x6": sum(1 for t in tams if t == (6, 6)),
                                "redondos_ge4px": len(redondos), "nota": "C18 pide brasas de 2–4 px irregulares con estela de 1 px"}
    # C4: silueta de la heroína en 18b
    d18b = medir_disposicion("18b_hero_death", cargar("18b_hero_death"))
    her = [l for l in d18b["luchadores"] if l["bbox_art"][0] < 220]
    out["C4_muerte_heroina"] = {"heroina_18b": her[0] if her else None,
                                "nota": "C4 pide silueta claramente horizontal (ancho > alto) en el suelo"}
    # C17: títulos de carta en mano frente a recompensa
    l7 = res["07_combat"]["legibilidad"]
    l13 = res["13_rewards"]["legibilidad"]
    out["C17_titulos"] = {"mano_alto_px": l7["carta_nombre_golpe"]["alto_tinta_px"], "mano_trazo": l7["carta_nombre_golpe"]["trazo_min_px"],
                          "recompensa_alto_px": l13["recompensa_titulo_1 (×1)"]["alto_tinta_px"],
                          "recompensa_trazo": l13["recompensa_titulo_1 (×1)"]["trazo_min_px"]}
    # C17: hueco entre el fin de «Tajo Ígneo» y el orbe de coste de la carta siguiente (07, fila y 606–616 px)
    k7 = cargar("07_combat")
    z = l7["carta_nombre_tajo"]
    x0, y0, x1, y1 = z["bbox_px"]
    tinta = int(z["tinta"], 16)
    ys, xs = np.nonzero(k7[y0:y1, x0:x1] == tinta)
    fin = x0 + int(xs.max())
    orbe = list(rampa("ember_ui") | rampa("fire"))
    fila = np.isin(k7[600:622, fin + 1:fin + 80], orbe).any(0)
    out["C17_tajo_orbe"] = {"fin_titulo_px": fin, "primer_px_orbe": int(fin + 1 + np.argmax(fila)) if fila.any() else None,
                            "hueco_px": int(np.argmax(fila)) if fila.any() else None}
    # F2-REV2 · contraste de valor (luminancia 0–1, mediana) de cuerpos oscuros contra su fondo, y textura del muro (C19)
    def lum_med(nombre, caja):
        g = np.asarray(Image.open(SHOTS / f"{nombre}.png").convert("L")).astype(float) / 255
        x0, y0, x1, y1 = caja
        return round(float(np.median(g[y0:y1, x0:x1])), 3)
    out["valor_cuerpo_fondo"] = {
        "ash_slime_07": {"cuerpo_px": [1110, 495, 1180, 515], "cuerpo": lum_med("07_combat", (1110, 495, 1180, 515)),
                         "suelo_px": [1060, 525, 1230, 532], "suelo": lum_med("07_combat", (1060, 525, 1230, 532))},
        "candle_mite_18b": {"cuerpo_px": [1122, 510, 1145, 520], "cuerpo": lum_med("18b_hero_death", (1122, 510, 1145, 520)),
                            "fondo_px": [1180, 508, 1250, 522], "fondo": lum_med("18b_hero_death", (1180, 508, 1250, 522))}}
    g7 = np.asarray(Image.open(SHOTS / "07_combat.png").convert("L")).astype(float)
    out["C19_muro_tras_enemigos"] = {"zona_px": [780, 130, 1000, 250], "desv_luminancia_0_255": round(float(g7[130:250, 780:1000].std()), 2),
                                     "nota": "F2-BASE/F2-VIDA (antes de F2-SALA): 16,08–16,23 en la misma zona"}
    # C20 · píxeles cambiados por fotograma en reposo (opcional): REPOSO_DIR con reposo_###.png de vida_capturas (30 fps)
    import os
    rd = os.environ.get("REPOSO_DIR")
    if rd and Path(rd).is_dir():
        fs = sorted(Path(rd).glob("reposo_*.png"))
        prev, d = None, []
        for f in fs:
            a_ = np.asarray(Image.open(f).convert("RGB"))
            if prev is not None:
                d.append(int((a_ != prev).any(2).sum()))
            prev = a_
        if d:
            out["C20_reposo"] = {"fotogramas": len(fs), "media_px": round(float(np.mean(d)), 1), "pico_px": int(max(d)),
                                 "pico_en": int(np.argmax(d)), "tope": 13800}
    return out


# ---------------------------------------------------------------- principal
def main() -> None:
    res = {"capturas": {}, "paleta_colores": len(PAL), "nota": __doc__.strip().splitlines()[0]}
    for f in sorted(SHOTS.glob("*.png")):
        nombre = f.stem
        im = Image.open(f).convert("RGB")
        k = clave(np.asarray(im))
        d = {"md5": hashlib.md5(f.read_bytes()).hexdigest(), "tam": list(im.size),
             "legado": nombre in LEGADO, "jefe_legado": nombre in JEFE_LEGADO, "combate": nombre in COMBATE}
        d["rejilla"] = medir_rejilla(nombre, k)
        d["paleta"] = medir_paleta(k)
        if nombre in ("08_combat_hover", "13_rewards", "19_shop", "23_cards"):
            d["ilustraciones"] = medir_ilustraciones(k, d["rejilla"]["cajas_pergamino_px"])
        if nombre in ("07_combat", "08_combat_hover", "09_burn", "10b_enemy_turn", "13_rewards"):
            zonas = {} if nombre in ("13_rewards", "10b_enemy_turn") else dict(ZONAS_HUD)
            zonas.update(ZONAS_EXTRA.get(nombre, {}))
            d["legibilidad"] = {z: medir_texto(k, bb) for z, bb in zonas.items()}
        if nombre in ("07_combat", "10b_enemy_turn", "11_after_enemy_turn", "14_boss_summon", "14a_summon_reveal",
                      "16_act2_hydra", "18_frost_king", "18b_hero_death"):
            d["disposicion"] = medir_disposicion(nombre, k)
        res["capturas"][nombre] = d
        print(f"{nombre}: rejilla {d['rejilla']['pct_bloques_2x2_no_uniformes']}% · fuera exc. "
              f"{d['rejilla']['pct_fuera_de_excepcion']}% · paleta {d['paleta']['pct_px_en_paleta']}% · "
              f"ajenos {d['paleta']['pct_px_ajenos']}%", flush=True)
    res["correcciones"] = medir_correcciones(res["capturas"])
    print(json.dumps(res["correcciones"], ensure_ascii=False)[:1500])
    OUT.write_text(json.dumps(res, ensure_ascii=False, indent=1), encoding="utf-8")
    print("escrito", OUT)


if __name__ == "__main__":
    main()
