#!/bin/bash
set -e
cd /Users/mac2-mayu/Quote-app/Marketing/UGC/2026-08-12-kirawareta-7slides
mkdir -p photos
run_one() {
  local name="$1"
  local scene="$2"
  HOME=/Users/mac2-mayu ZDOTDIR=/tmp codex exec --full-auto -s workspace-write "Use Codex built-in image generation/image_gen to create exactly one text-free realistic lifestyle photograph. Do not use Python, Pillow, SVG, Canvas, HTML, CSS, or programmatic drawing. Save the final PNG as photos/${name}.png in the current folder. Portrait 1080x1920, no visible text, logos, watermarks, UI, or readable writing, no faces, hands allowed. Warm natural nighttime indoor light, muted beige and dusty rose palette, consistent photographic world. Scene: ${scene}. Make this composition distinct from any other slide." || exit 1
}
run_one p02-reply "close-up of a hand holding a phone above a wooden desk, the screen blank and unreadable, a cup of tea and notebook nearby, hesitation before replying, diagonal composition"
run_one p03-reason "top-down view of a phone being placed face down beside a ceramic cup on a small table, soft evening light, quiet decisive action"
run_one p04-mood "side view of a quiet room after a conversation, phone resting on a low table beside a warm lamp, empty chair in background, reflective mood"
run_one p05-table "overhead view of a small dining table with two place settings, one hand removing one plate, intimate home at night, no faces"
run_one p06-bedphone "close side view of a person in bed holding a phone upright, phone screen is a clean blank pale abstract rectangle with no UI or text, dark bedroom, ample screen area for later perspective compositing"
run_one p07-recap "still life of a calm bedside table at night, closed notebook, warm small lamp, folded cloth, soft shadows, peaceful closing mood"
