#!/usr/bin/env python3
"""Recolor CotEditor icon resources from green to blue for a private build.

This script intentionally touches only icon resources:
- CotEditor/Resources/AppIcon.icon/icon.json
- PNGs under CotEditor/Resources/Assets.xcassets/Icons/* Icons/*.iconset

The resulting icons are for a personal custom build. Do not redistribute them
or submit them upstream without separately checking the image asset license.
"""

from __future__ import annotations

import colorsys
from pathlib import Path

try:
    from PIL import Image
except ImportError as error:
    raise SystemExit(
        "Pillow is required to recolor PNG iconsets. "
        "Install it in your local Python environment, then rerun this script."
    ) from error


ROOT = Path(__file__).resolve().parents[1]
APP_ICON_JSON = ROOT / "CotEditor/Resources/AppIcon.icon/icon.json"
ICONSETS_ROOT = ROOT / "CotEditor/Resources/Assets.xcassets/Icons"

# Softer blue palette chosen to keep CotEditor's contrast while avoiding a dark
# Finder document icon background.
APP_ICON_GRADIENT = [
    "display-p3:0.43137,0.60784,0.90980,1.00000",
    "display-p3:0.65098,0.81569,1.00000,1.00000",
]

# HSV target range for the green iconset backgrounds and glyph accents.
TARGET_BLUE_HUE = 0.605


def recolor_icon_json() -> None:
    text = APP_ICON_JSON.read_text()
    text = text.replace(
        '"display-p3:0.30400,0.60000,0.12000,1.00000",\n'
        '              "display-p3:0.60240,0.72000,0.21600,1.00000"',
        f'"{APP_ICON_GRADIENT[0]}",\n'
        f'              "{APP_ICON_GRADIENT[1]}"',
    )
    text = text.replace(
        '"display-p3:0.30000,0.43500,0.88200,1.00000",\n'
        '              "display-p3:0.55200,0.74900,0.98400,1.00000"',
        f'"{APP_ICON_GRADIENT[0]}",\n'
        f'              "{APP_ICON_GRADIENT[1]}"',
    )
    text = text.replace('"name" : "Green"', '"name" : "Blue"')
    APP_ICON_JSON.write_text(text)


def recolor_pixel(red: int, green: int, blue: int, alpha: int) -> tuple[int, int, int, int]:
    if alpha == 0:
        return red, green, blue, alpha

    r = red / 255
    g = green / 255
    b = blue / 255
    h, s, v = colorsys.rgb_to_hsv(r, g, b)

    # Recolor saturated yellow-green/green pixels and leave neutral white/gray
    # page shapes, text glyphs, and shadows intact.
    is_green = 0.16 <= h <= 0.42 and s >= 0.18 and g >= max(r, b) * 1.08
    if not is_green:
        return red, green, blue, alpha

    # Preserve perceived depth: darker greens become deeper blue, brighter
    # yellow-greens become lighter blue. Keep small glyphs readable at 16px.
    new_saturation = min(0.56, max(0.30, s * 0.64))
    new_value = min(1.0, max(0.25, v * 1.13))
    nr, ng, nb = colorsys.hsv_to_rgb(TARGET_BLUE_HUE, new_saturation, new_value)
    return round(nr * 255), round(ng * 255), round(nb * 255), alpha


def recolor_png(path: Path) -> None:
    image = Image.open(path).convert("RGBA")
    data = image.get_flattened_data() if hasattr(image, "get_flattened_data") else image.getdata()
    pixels = [recolor_pixel(*pixel) for pixel in data]
    image.putdata(pixels)
    image.save(path)


def recolor_iconsets() -> None:
    for path in sorted(ICONSETS_ROOT.glob("* Icons/*.iconset/*.png")):
        recolor_png(path)


def main() -> None:
    recolor_icon_json()
    recolor_iconsets()


if __name__ == "__main__":
    main()
