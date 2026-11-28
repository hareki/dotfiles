#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["fonttools"]
# ///
"""Build the Maple Mono NF Rex family from the installed Maple Mono NF.

Rex sets the face of regular text only, and takes bold and italic from the family's own faces. This
family fills each of its four slots with the face one weight step heavier, so the shift happens in
the font. Only the names and the style flags change: the outlines are the source's
"""

from pathlib import Path

from fontTools.ttLib import TTFont

FONTS = Path.home() / "Library/Fonts"
SOURCE = "MapleMono-NF"
FAMILY = "Maple Mono NF Rex"
POSTSCRIPT = "MapleMono-NF-Rex"
# fsSelection's ITALIC, BOLD and REGULAR bits
STYLE_BITS = 0x61
# The source face and the slot it fills, then the slot's usWeightClass, fsSelection style bits and
# macStyle. Maple Mono NF's own face of that name carries the same three, not the outlines' real
# weight, so a lookup for the family's bold lands on the Bold slot
FACES = [
    ("SemiBold", "Regular", 400, 0x40, 0x0),
    ("ExtraBold", "Bold", 700, 0x20, 0x1),
    ("SemiBoldItalic", "Italic", 400, 0x01, 0x2),
    ("ExtraBoldItalic", "Bold Italic", 700, 0x21, 0x3),
]


def build(source: str, style: str, weight: int, selection: int, mac_style: int) -> Path:
    source_name = f"{SOURCE}-{source}"
    postscript_name = f"{POSTSCRIPT}-{style.replace(' ', '')}"
    # The source's timestamp stays, so a second run writes the same bytes
    font = TTFont(FONTS / f"{source_name}.ttf", recalcTimestamp=False)

    names = {1: FAMILY, 2: style, 4: f"{FAMILY} {style}", 6: postscript_name}
    table = font["name"]
    for record in table.names:
        if record.nameID in names:
            record.string = names[record.nameID]
        elif record.nameID == 3:
            record.string = record.toUnicode().replace(source_name, postscript_name)
    # The typographic family and style, which file the source face under Maple Mono NF
    table.removeNames(nameID=16)
    table.removeNames(nameID=17)

    os2 = font["OS/2"]
    os2.usWeightClass = weight
    os2.fsSelection = (os2.fsSelection & ~STYLE_BITS) | selection
    font["head"].macStyle = mac_style

    target = FONTS / f"{postscript_name}.ttf"
    font.save(target)
    return target


for face in FACES:
    print(build(*face))
