extends "res://scripts/art/legacy/legacy_events.gd"
## Art: banco de pixel art. Todo el arte vive como datos versionables (sin binarios):
##  - SPRITES: mapas ASCII a mano (heroína 24×36 + brazo 10×20, iconos 12×12).
##  - BASES: monstruos dibujados a mano mirando a la izquierda; SHAPES: medias máscaras para
##    criaturas frontales. Ambos se sombrean (campo de distancia + luz cenital + luz de fuego lateral)
##    y varían por semilla (grietas emisivas, piezas opcionales, ligera deriva de tono).
##  - card_frame() / card_art(): marco 75×105 e ilustración 60×30, ambos a ×2 (misma rejilla).
##  - background(): composición distinta por acto; background_near(): capa de primer plano.
##  - forge_sprite(), furnace_small(), bonfire(), event_art(), door_art(), logo().
## REGLA: todo el mundo se dibuja a ×4 (UI.PX) y la interfaz a ×2. Ver docs/ART_BIBLE.md.

##
## v0.4: este autoload es una FACHADA. El arte v0.3 vive troceado en scripts/art/legacy/ (cadena de herencia,
## congelado y protegido por tests/art/legacy_hashes.json). El arte nuevo se hornea con el rig
## (scripts/art/rig/, tools/bake_art.gd) y se sirve por SpriteBank; la API pública de Art no cambia.
