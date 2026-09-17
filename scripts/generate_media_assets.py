#!/usr/bin/env python3
"""
scripts/generate_media_assets.py
Generates authentic, high-impact brand media assets for Khomyak (Хомяк) v1.0.1:
1. README Hero Banner (1200x520) with Canonical 3D Bauhaus Hamster
2. OpenGraph Banner (1280x640)
3. 4 Authentic Feature Visuals (880x460 each) showing real HUD, keycaps, and toolkits
"""

import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

REPO_ROOT = Path("/Users/igorekishev/Igor/igorekishev/mac-productivity-suite")
ASSETS_DIR = REPO_ROOT / "assets"
FEATURES_DIR = ASSETS_DIR / "features"
ASSETS_DIR.mkdir(parents=True, exist_ok=True)
FEATURES_DIR.mkdir(parents=True, exist_ok=True)

# Mascot and reference paths
HERO_MASCOT_PATH = ASSETS_DIR / "khomyak_reference_keyboard_hero.png"
BAUHAUS_KEYCAP_PATH = ASSETS_DIR / "explorations/khomyak_bauhaus_identity_appicon.jpg"
APP_ICON_PATH = ASSETS_DIR / "AppIcon.png"

CHROME_ICON_PATH = FEATURES_DIR / "icon_chrome.png"
TERMINAL_ICON_PATH = FEATURES_DIR / "icon_terminal.png"
NOTES_ICON_PATH = FEATURES_DIR / "icon_notes.png"
OBSIDIAN_ICON_PATH = FEATURES_DIR / "icon_obsidian.png"

# Colors
C_MIDNIGHT = (11, 17, 32)        # #0B1120
C_NAVY_DARK = (6, 11, 24)        # #060B18
C_CARD_BG = (18, 26, 46)         # #121A2E
C_CARD_SURFACE = (24, 35, 60)    # #18233C
C_GOLD = (245, 166, 35)          # #F5A623
C_GOLD_LIGHT = (255, 215, 100)   # #FFD764
C_CYAN = (56, 189, 248)          # #38BDF8
C_CYAN_GLOW = (130, 200, 250)    # #82C8FA
C_BORDER = (38, 52, 85)          # #263455
C_TEXT_WHITE = (248, 250, 252)   # #F8FAFC
C_TEXT_MUTED = (148, 163, 184)   # #94A3B8
C_GREEN = (52, 211, 153)         # #34D399
C_PURPLE = (168, 85, 247)        # #A855F7
C_CORAL = (239, 68, 68)          # #EF4444

def get_font(size: int = 24, bold: bool = True):
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/HelveticaNeue.ttc",
    ]
    for c in candidates:
        if Path(c).exists():
            try:
                return ImageFont.truetype(c, size)
            except Exception:
                continue
    return ImageFont.load_default()

def wrap_text(text: str, max_chars: int = 44):
    words = text.split()
    lines = []
    cur = []
    for w in words:
        cur.append(w)
        if len(" ".join(cur)) > max_chars:
            lines.append(" ".join(cur[:-1]))
            cur = [w]
    if cur:
        lines.append(" ".join(cur))
    return lines

def draw_pill(draw, xy, text, font, fill=C_CARD_BG, outline=C_CYAN, text_color=C_CYAN, radius=10, pad_x=12, pad_y=5):
    bbox = draw.textbbox((0, 0), text, font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    x0, y0 = xy
    x1 = x0 + w + pad_x * 2
    y1 = y0 + h + pad_y * 2
    draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=fill, outline=outline, width=1)
    draw.text((x0 + pad_x, y0 + pad_y - 1), text, fill=text_color, font=font)
    return x1, y1

def create_radial_gradient(width, height, center, radius, color_inner, color_outer):
    base = Image.new("RGBA", (width, height), color_outer)
    gw, gh = width // 2, height // 2
    cx, cy = center[0] / 2, center[1] / 2
    gr = radius / 2
    mask = Image.new("L", (gw, gh), 0)
    for y in range(gh):
        for x in range(gw):
            dist = math.sqrt((x - cx)**2 + (y - cy)**2)
            factor = max(0.0, min(1.0, 1.0 - (dist / gr)))
            factor = factor * factor * (3 - 2 * factor)
            mask.putpixel((x, y), int(factor * 255))
    mask = mask.resize((width, height), Image.Resampling.BICUBIC)
    inner_layer = Image.new("RGBA", (width, height), color_inner)
    base.paste(inner_layer, (0, 0), mask)
    return base

# -------------------------------------------------------------
# 1. README Hero Banner (1200x520)
# -------------------------------------------------------------
def generate_readme_hero():
    w, h = 1200, 520
    bg = create_radial_gradient(w, h, (300, 260), 550, (26, 40, 78, 255), (11, 17, 32, 255))
    gold_glow = create_radial_gradient(w, h, (240, 260), 320, (245, 166, 35, 45), (0, 0, 0, 0))
    bg = Image.alpha_composite(bg, gold_glow)
    draw = ImageDraw.Draw(bg)

    # 3D Bauhaus Hamster Mascot (Left side)
    if HERO_MASCOT_PATH.exists():
        mascot = Image.open(HERO_MASCOT_PATH).convert("RGBA")
        mw, mh = 420, 420
        mascot = mascot.resize((mw, mh), Image.Resampling.LANCZOS)
        bg.paste(mascot, (30, 50), mascot)

    # Content (Right side)
    fx = 490

    # Badges
    f_badge = get_font(12, bold=True)
    p1, _ = draw_pill(draw, (fx, 48), "100% NATIVE SWIFT 6", f_badge, outline=C_CYAN, text_color=C_CYAN)
    p2, _ = draw_pill(draw, (p1 + 8, 48), "SUB-16MS FLOW", f_badge, outline=C_GOLD, text_color=C_GOLD)
    draw_pill(draw, (p2 + 8, 48), "ZERO DRIVERS", f_badge, outline=C_GREEN, text_color=C_GREEN)

    # Title & Slogan
    f_title = get_font(52, bold=True)
    draw.text((fx, 90), "Khomyak", fill=C_TEXT_WHITE, font=f_title)

    f_slogan = get_font(25, bold=True)
    draw.text((fx, 154), "Tap the Hamster. Own the Flow.", fill=C_GOLD, font=f_slogan)

    f_sub = get_font(15, bold=False)
    sub_lines = [
        "The driverless macOS hyper-key that transforms your Caps-Lock into an",
        "instantaneous workspace switch for Chrome profiles, Terminal, IDE, and",
        "universal Linux-style Copy-on-Select in sub-16ms single display frames."
    ]
    sy = 196
    for line in sub_lines:
        draw.text((fx, sy), line, fill=C_TEXT_MUTED, font=f_sub)
        sy += 24

    # Metrics Strip
    my = 282
    draw.rounded_rectangle([fx, my, fx + 660, my + 64], radius=12, fill=C_CARD_BG, outline=C_BORDER, width=1)
    f_mval = get_font(17, bold=True)
    f_mlbl = get_font(12, bold=False)

    col_w = 165
    metrics = [
        ("0 ms", "Added Latency", C_CYAN),
        ("15 MB", "RAM Footprint", C_GREEN),
        ("Universal", "arm64 + x86_64", C_GOLD),
        ("100% Free", "MIT Open Source", C_TEXT_WHITE)
    ]
    for i, (val, lbl, color) in enumerate(metrics):
        cx = fx + i * col_w + 18
        draw.text((cx, my + 12), val, fill=color, font=f_mval)
        draw.text((cx, my + 36), lbl, fill=C_TEXT_MUTED, font=f_mlbl)
        if i < 3:
            draw.line([fx + (i + 1) * col_w, my + 14, fx + (i + 1) * col_w, my + 50], fill=C_BORDER, width=1)

    # Home-Row Key Ribbon
    ry = 362
    draw.rounded_rectangle([fx, ry, fx + 660, ry + 110], radius=12, fill=(15, 23, 42, 230), outline=C_BORDER, width=1)
    draw.text((fx + 16, ry + 12), "TACTILE HOME-ROW CONTROLS", fill=C_CYAN, font=f_badge)

    f_key = get_font(13, bold=True)
    f_action = get_font(13, bold=False)

    # Row 1
    k1, _ = draw_pill(draw, (fx + 16, ry + 36), "Caps Tap", f_key, fill=(28, 38, 66), outline=C_CYAN, text_color=C_TEXT_WHITE, pad_x=8, pad_y=3)
    draw.text((k1 + 8, ry + 40), "-> Esc (Vim / Modals)", fill=C_TEXT_MUTED, font=f_action)

    k2, _ = draw_pill(draw, (fx + 350, ry + 36), "Caps Hold", f_key, fill=(28, 38, 66), outline=C_PURPLE, text_color=C_TEXT_WHITE, pad_x=8, pad_y=3)
    draw.text((k2 + 8, ry + 40), "-> Hyper Modifier", fill=C_TEXT_MUTED, font=f_action)

    # Row 2
    k3, _ = draw_pill(draw, (fx + 16, ry + 72), "Caps + C", f_key, fill=(28, 38, 66), outline=C_GOLD, text_color=C_GOLD_LIGHT, pad_x=8, pad_y=3)
    draw.text((k3 + 8, ry + 76), "-> Chrome Profiles", fill=C_TEXT_MUTED, font=f_action)

    k4, _ = draw_pill(draw, (fx + 350, ry + 72), "Caps + T / I / A / N", f_key, fill=(28, 38, 66), outline=C_GREEN, text_color=C_GREEN, pad_x=8, pad_y=3)
    draw.text((k4 + 8, ry + 76), "-> 5-App Toolkit", fill=C_TEXT_MUTED, font=f_action)

    out = ASSETS_DIR / "khomyak_readme_hero.png"
    bg.save(out, "PNG")
    print(f"Generated: {out}")

# -------------------------------------------------------------
# 2. Feature 1: Dual-Role Caps-Lock Hyper Key (880x460)
# -------------------------------------------------------------
def generate_feature_caps_hyper():
    w, h = 880, 460
    bg = create_radial_gradient(w, h, (440, 230), 500, (22, 34, 64, 255), (10, 15, 28, 255))
    draw = ImageDraw.Draw(bg)
    draw.rounded_rectangle([16, 16, w - 16, h - 16], radius=16, outline=C_BORDER, width=2)

    # Left: Bauhaus Caps-Lock Keycap Monolith Artwork
    if BAUHAUS_KEYCAP_PATH.exists():
        art = Image.open(BAUHAUS_KEYCAP_PATH).convert("RGBA")
        art = art.resize((360, 360), Image.Resampling.LANCZOS)
        mask = Image.new("L", (360, 360), 0)
        mask_draw = ImageDraw.Draw(mask)
        mask_draw.rounded_rectangle([0, 0, 360, 360], radius=24, fill=255)
        bg.paste(art, (40, 50), mask)
        draw.rounded_rectangle([40, 50, 400, 410], radius=24, outline=C_BORDER, width=2)

    # Right: Technical Flow Diagram
    rx = 430
    f_badge = get_font(12, bold=True)
    draw_pill(draw, (rx, 45), "DUAL-ROLE HARDWARE REMAP", f_badge, outline=C_CYAN, text_color=C_CYAN)

    f_title = get_font(26, bold=True)
    draw.text((rx, 80), "Dual-Role Caps-Lock Key", fill=C_TEXT_WHITE, font=f_title)

    f_sub = get_font(14, bold=False)
    draw.text((rx, 116), "Home-row hardware weapon with zero background daemons.", fill=C_TEXT_MUTED, font=f_sub)

    f_bhead = get_font(14, bold=True)
    f_bdesc = get_font(12, bold=False)

    # Flow Box 1: Tap
    b1_y = 152
    draw.rounded_rectangle([rx, b1_y, w - 40, b1_y + 76], radius=12, fill=C_CARD_BG, outline=C_CYAN, width=1)
    draw.ellipse([rx + 16, b1_y + 18, rx + 28, b1_y + 30], fill=C_CYAN)
    draw.text((rx + 38, b1_y + 14), "Tapped Alone (< 200ms) -> Emits Escape (0x35)", fill=C_TEXT_WHITE, font=f_bhead)
    draw.text((rx + 38, b1_y + 38), "Instant escape for Vim, Helix, terminal and dialogs.\nZero wrist travel to top-left corner.", fill=C_TEXT_MUTED, font=f_bdesc)

    # Flow Box 2: Hold
    b2_y = 240
    draw.rounded_rectangle([rx, b2_y, w - 40, b2_y + 76], radius=12, fill=C_CARD_BG, outline=C_PURPLE, width=1)
    draw.ellipse([rx + 16, b2_y + 18, rx + 28, b2_y + 30], fill=C_PURPLE)
    draw.text((rx + 38, b2_y + 14), "Held Down -> Acts as Hyper Modifier", fill=C_TEXT_WHITE, font=f_bhead)
    draw.text((rx + 38, b2_y + 38), "Synthesizes Shift + Ctrl + Option + Command.\nCaps-Lock LED never toggles; zero screaming ALL CAPS.", fill=C_TEXT_MUTED, font=f_bdesc)

    # Flow Box 3: Driverless
    b3_y = 328
    draw.rounded_rectangle([rx, b3_y, w - 40, b3_y + 76], radius=12, fill=C_CARD_BG, outline=C_GREEN, width=1)
    draw.ellipse([rx + 16, b3_y + 18, rx + 28, b3_y + 30], fill=C_GREEN)
    draw.text((rx + 38, b3_y + 14), "100% Driverless Native Architecture", fill=C_TEXT_WHITE, font=f_bhead)
    draw.text((rx + 38, b3_y + 38), "Hardware remap via IOHID (hidutil) + CoreGraphics CGEventTap.\nNo kernel extensions or Karabiner daemon overhead.", fill=C_TEXT_MUTED, font=f_bdesc)

    out = FEATURES_DIR / "feature_caps_hyper.png"
    bg.save(out, "PNG")
    print(f"Generated: {out}")

# -------------------------------------------------------------
# 3. Feature 2: Chrome Profile Switcher & HUD (880x460)
# -------------------------------------------------------------
def generate_feature_chrome_switch():
    w, h = 880, 460
    bg = create_radial_gradient(w, h, (440, 230), 500, (20, 32, 60, 255), (10, 15, 28, 255))
    draw = ImageDraw.Draw(bg)
    draw.rounded_rectangle([16, 16, w - 16, h - 16], radius=16, outline=C_BORDER, width=2)

    # Left: Authentic SwiftUI MinimalHUDWindow Mockup
    hud_x, hud_y = 44, 70
    hud_w, hud_h = 330, 320
    draw.rounded_rectangle([hud_x, hud_y, hud_x + hud_w, hud_y + hud_h], radius=22, fill=(35, 42, 58, 240), outline=(60, 75, 105), width=2)
    in_pad = 12
    draw.rounded_rectangle([hud_x + in_pad, hud_y + in_pad, hud_x + hud_w - in_pad, hud_y + hud_h - in_pad], radius=16, fill=(64, 108, 171), outline=C_CYAN_GLOW, width=2)

    # 72pt Chrome Icon
    if CHROME_ICON_PATH.exists():
        c_icon = Image.open(CHROME_ICON_PATH).convert("RGBA")
        c_icon = c_icon.resize((72, 72), Image.Resampling.LANCZOS)
        imask = Image.new("L", (72, 72), 0)
        idraw = ImageDraw.Draw(imask)
        idraw.rounded_rectangle([0, 0, 72, 72], radius=16, fill=255)
        bg.paste(c_icon, (hud_x + (hud_w - 72) // 2, hud_y + 36), imask)

    f_hud_title = get_font(15, bold=True)
    ht = "Google Chrome"
    hbbox = draw.textbbox((0, 0), ht, font=f_hud_title)
    draw.text((hud_x + (hud_w - (hbbox[2] - hbbox[0])) // 2, hud_y + 120), ht, fill=C_TEXT_WHITE, font=f_hud_title)

    # Profile Avatar Row
    avatars = [
        ("I", "Igor", (244, 63, 94), False),
        ("N", "Nastya", (16, 185, 129), True),
        ("A", "Al11", (245, 158, 11), False),
        ("G", "Trial", (6, 182, 212), False),
    ]
    row_y = hud_y + 175
    spacing = 62
    start_x = hud_x + 44
    f_mono = get_font(14, bold=True)
    f_pname = get_font(11, bold=False)

    for idx, (initial, name, col, is_sel) in enumerate(avatars):
        ax = start_x + idx * spacing
        if is_sel:
            draw.ellipse([ax - 4, row_y - 4, ax + 36, row_y + 36], outline=C_CYAN_GLOW, width=2)
        draw.ellipse([ax, row_y, ax + 32, row_y + 32], fill=col)
        draw.text((ax + 10, row_y + 7), initial, fill=C_TEXT_WHITE, font=f_mono)
        nb = draw.textbbox((0, 0), name, font=f_pname)
        draw.text((ax + 16 - (nb[2] - nb[0]) // 2, row_y + 44), name, fill=C_TEXT_WHITE if is_sel else C_TEXT_MUTED, font=f_pname)

    # Shortcut hint badge in HUD
    f_hud_hint = get_font(12, bold=True)
    draw.rounded_rectangle([hud_x + 36, hud_y + 250, hud_x + hud_w - 36, hud_y + 285], radius=8, fill=(30, 48, 85), outline=(90, 130, 190), width=1)
    hint_str = "Caps + 2 -> Switched in 12ms"
    hbb = draw.textbbox((0, 0), hint_str, font=f_hud_hint)
    draw.text((hud_x + (hud_w - (hbb[2] - hbb[0])) // 2, hud_y + 260), hint_str, fill=C_GOLD_LIGHT, font=f_hud_hint)

    # Right: Features
    rx = 415
    f_badge = get_font(12, bold=True)
    draw_pill(draw, (rx, 45), "SUB-16MS ACCESSIBILITY ENGINE", f_badge, outline=C_GOLD, text_color=C_GOLD)

    f_title = get_font(26, bold=True)
    draw.text((rx, 80), "Chrome Multi-Profile Switcher", fill=C_TEXT_WHITE, font=f_title)

    f_sub = get_font(14, bold=False)
    draw.text((rx, 116), "The instant cure for the 4th Profile Pain.", fill=C_TEXT_MUTED, font=f_sub)

    f_bhead = get_font(14, bold=True)
    f_bdesc = get_font(11, bold=False)

    points = [
        ("Caps-Lock + C -> Instant Cycling", "Cycle open Chromium windows in 1 display frame (<16ms) without touching the mouse.", C_GOLD),
        ("Caps-Lock + 1..4 -> Direct Slot Jump", "Jump straight to Profile 1, 2, 3, or 4 via number keys without scanning menus.", C_CYAN),
        ("Native AXUIElement Window Raising", "Zero tab clutter. Focuses existing windows with no AppleScript lag.", C_GREEN),
        ("Dynamic Chromium Profile Discovery", "Auto-reads Local State for Google Chrome, Brave, Edge with authentic avatars.", C_PURPLE)
    ]
    py = 150
    for head, desc, col in points:
        draw.rounded_rectangle([rx, py, w - 36, py + 62], radius=10, fill=C_CARD_BG, outline=col, width=1)
        draw.ellipse([rx + 14, py + 26, rx + 24, py + 36], fill=col)
        draw.text((rx + 36, py + 10), head, fill=C_TEXT_WHITE, font=f_bhead)
        lines = wrap_text(desc, max_chars=46)
        dy = py + 28
        for ln in lines:
            draw.text((rx + 36, dy), ln, fill=C_TEXT_MUTED, font=f_bdesc)
            dy += 15
        py += 72

    out = FEATURES_DIR / "feature_chrome_switch.png"
    bg.save(out, "PNG")
    print(f"Generated: {out}")

# -------------------------------------------------------------
# 4. Feature 3: 5-App Toolkit Fast Switcher (880x460)
# -------------------------------------------------------------
def generate_feature_toolkit_switch():
    w, h = 880, 460
    bg = create_radial_gradient(w, h, (440, 230), 500, (20, 35, 50, 255), (10, 15, 28, 255))
    draw = ImageDraw.Draw(bg)
    draw.rounded_rectangle([16, 16, w - 16, h - 16], radius=16, outline=C_BORDER, width=2)

    # Top: App Toolkit Grid / Dock Display
    f_badge = get_font(12, bold=True)
    draw_pill(draw, (44, 40), "HOME-ROW MNEMONIC ROUTING", f_badge, outline=C_GREEN, text_color=C_GREEN)

    f_title = get_font(26, bold=True)
    draw.text((44, 75), "5-App Toolkit Fast Switcher", fill=C_TEXT_WHITE, font=f_title)

    f_sub = get_font(14, bold=False)
    draw.text((44, 110), "Brain thinks in tool names: Think tool -> Press home-row first letter.", fill=C_TEXT_MUTED, font=f_sub)

    # Visual App Dock Row
    dock_y = 145
    dock_w = w - 88
    draw.rounded_rectangle([44, dock_y, 44 + dock_w, dock_y + 130], radius=18, fill=(18, 26, 44, 230), outline=C_BORDER, width=1)

    tools = [
        ("Terminal", "Caps + T", TERMINAL_ICON_PATH, C_GREEN),
        ("IDE", "Caps + I", None, C_PURPLE),
        ("AI Agent", "Caps + A", APP_ICON_PATH, C_CYAN),
        ("Notes", "Caps + N", NOTES_ICON_PATH, C_GOLD),
        ("Chrome", "Caps + C", CHROME_ICON_PATH, C_CORAL)
    ]
    slot_w = dock_w // 5
    f_tname = get_font(14, bold=True)
    f_tkey = get_font(12, bold=True)

    for i, (tname, tkey, ipath, col) in enumerate(tools):
        sx = 44 + i * slot_w + 12
        sy = dock_y + 16

        # App Icon
        if ipath and ipath.exists():
            icon = Image.open(ipath).convert("RGBA")
            icon = icon.resize((48, 48), Image.Resampling.LANCZOS)
            imask = Image.new("L", (48, 48), 0)
            idraw = ImageDraw.Draw(imask)
            idraw.rounded_rectangle([0, 0, 48, 48], radius=12, fill=255)
            bg.paste(icon, (sx + 45, sy), imask)
        else:
            draw.rounded_rectangle([sx + 45, sy, sx + 93, sy + 48], radius=12, fill=(30, 41, 68), outline=col, width=1)
            draw.text((sx + 57, sy + 14), "</>", fill=col, font=f_tname)

        draw_pill(draw, (sx + 35, sy + 56), tkey, f_tkey, fill=(28, 38, 66), outline=col, text_color=col, pad_x=8, pad_y=2)
        nb = draw.textbbox((0, 0), tname, font=f_tname)
        draw.text((sx + 69 - (nb[2] - nb[0]) // 2, sy + 88), tname, fill=C_TEXT_WHITE, font=f_tname)

    # Bottom 3 Architecture Feature Cards
    by = 295
    f_bhead = get_font(13, bold=True)
    f_bdesc = get_font(11, bold=False)

    b_cards = [
        ("Dynamic Letter Cycling", "Have multiple IDEs (Xcode + Cursor)? Subsequent taps cycle candidates automatically.", C_PURPLE),
        ("Sub-16ms Window Focus", "Focuses existing macOS windows directly via Accessibility APIs in 1 display frame.", C_GREEN),
        ("4 Pinned Slots Customizer", "Customize your 4 core tools in 1 click from the status menu with zero restarts.", C_GOLD)
    ]
    bc_w = (w - 88 - 24) // 3
    for j, (head, desc, col) in enumerate(b_cards):
        bx = 44 + j * (bc_w + 12)
        draw.rounded_rectangle([bx, by, bx + bc_w, by + 120], radius=12, fill=C_CARD_BG, outline=col, width=1)
        draw.ellipse([bx + 14, by + 18, bx + 22, by + 26], fill=col)
        draw.text((bx + 30, by + 14), head, fill=C_TEXT_WHITE, font=f_bhead)
        lines = wrap_text(desc, max_chars=28)
        dy = by + 40
        for ln in lines:
            draw.text((bx + 14, dy), ln, fill=C_TEXT_MUTED, font=f_bdesc)
            dy += 18

    out = FEATURES_DIR / "feature_toolkit_switch.png"
    bg.save(out, "PNG")
    print(f"Generated: {out}")

# -------------------------------------------------------------
# 5. Feature 4: Linux Copy-on-Select (880x460)
# -------------------------------------------------------------
def generate_feature_copy_select():
    w, h = 880, 460
    bg = create_radial_gradient(w, h, (440, 230), 500, (24, 20, 48, 255), (10, 15, 28, 255))
    draw = ImageDraw.Draw(bg)
    draw.rounded_rectangle([16, 16, w - 16, h - 16], radius=16, outline=C_BORDER, width=2)

    # Left: Mock Editor Window with Selection & Floating Toast
    mx, my = 44, 60
    mw, mh = 340, 340
    draw.rounded_rectangle([mx, my, mx + mw, my + mh], radius=14, fill=(15, 20, 35), outline=(45, 55, 80), width=1)
    draw.rounded_rectangle([mx, my, mx + mw, my + 34], radius=14, fill=(22, 28, 46))
    draw.line([mx, my + 34, mx + mw, my + 34], fill=(35, 45, 70), width=1)
    draw.ellipse([mx + 12, my + 11, mx + 24, my + 23], fill=(239, 68, 68))
    draw.ellipse([mx + 30, my + 11, mx + 42, my + 23], fill=(245, 158, 11))
    draw.ellipse([mx + 48, my + 11, mx + 60, my + 23], fill=(16, 185, 129))
    f_win_title = get_font(12, bold=False)
    draw.text((mx + 105, my + 9), "main.swift — Xcode", fill=C_TEXT_MUTED, font=f_win_title)

    f_code = get_font(12, bold=False)
    code_lines = [
        "func handleSelection() {",
        "    let text = getHighlightedText()",
        "    // Drag distance > 10pt",
        "    NSPasteboard.general.copy(text)",
        "    notifySuccess()",
        "}"
    ]
    cy = my + 54
    for i, cl in enumerate(code_lines):
        if i == 3:
            draw.rectangle([mx + 16, cy - 2, mx + mw - 16, cy + 18], fill=(56, 189, 248, 90))
            draw.text((mx + 20, cy), cl, fill=C_TEXT_WHITE, font=f_code)
        else:
            draw.text((mx + 20, cy), cl, fill=(140, 160, 190), font=f_code)
        cy += 24

    toast_x, toast_y = mx + 40, my + 220
    draw.rounded_rectangle([toast_x, toast_y, toast_x + 260, toast_y + 46], radius=12, fill=(24, 38, 70, 250), outline=C_CYAN_GLOW, width=2)
    f_toast = get_font(13, bold=True)
    draw.text((toast_x + 16, toast_y + 14), "[Copied to Clipboard!]", fill=C_CYAN_GLOW, font=f_toast)

    px, py = mx + 250, my + 130
    draw.polygon([(px, py), (px, py + 18), (px + 5, py + 14), (px + 12, py + 22), (px + 15, py + 20), (px + 8, py + 12), (px + 14, py + 12)], fill=C_TEXT_WHITE, outline=(0, 0, 0))

    # Right: Features
    rx = 415
    f_badge = get_font(12, bold=True)
    draw_pill(draw, (rx, 45), "X11 SELECTION ERGONOMICS", f_badge, outline=C_PURPLE, text_color=C_PURPLE)

    f_title = get_font(26, bold=True)
    draw.text((rx, 80), "Linux Copy-on-Select", fill=C_TEXT_WHITE, font=f_title)

    f_sub = get_font(14, bold=False)
    draw.text((rx, 116), "Highlight text anywhere on macOS. It's already copied.", fill=C_TEXT_MUTED, font=f_sub)

    f_bhead = get_font(14, bold=True)
    f_bdesc = get_font(11, bold=False)

    points = [
        ("Mouse Drag Selection (> 10pt)", "Select text with a mouse drag. Release mouse to copy immediately.", C_PURPLE),
        ("Multi-Click Quick Copy", "Double-click a word or triple-click a paragraph to copy in 1 click.", C_CYAN),
        ("Modifier-Key Protection", "Ignores Cmd/Ctrl drags to preserve canvas panning and window moves.", C_GREEN),
        ("Universal Across macOS", "Works inside browsers, terminals, code editors, and PDF viewers.", C_GOLD)
    ]
    py = 150
    for head, desc, col in points:
        draw.rounded_rectangle([rx, py, w - 36, py + 62], radius=10, fill=C_CARD_BG, outline=col, width=1)
        draw.ellipse([rx + 14, py + 26, rx + 24, py + 36], fill=col)
        draw.text((rx + 36, py + 10), head, fill=C_TEXT_WHITE, font=f_bhead)
        lines = wrap_text(desc, max_chars=46)
        dy = py + 28
        for ln in lines:
            draw.text((rx + 36, dy), ln, fill=C_TEXT_MUTED, font=f_bdesc)
            dy += 15
        py += 72

    out = FEATURES_DIR / "feature_copy_select.png"
    bg.save(out, "PNG")
    print(f"Generated: {out}")

# -------------------------------------------------------------
# 6. OpenGraph Social Share Preview (1280x640)
# -------------------------------------------------------------
def generate_opengraph_banner():
    w, h = 1280, 640
    bg = create_radial_gradient(w, h, (360, 320), 600, (26, 42, 80, 255), (10, 15, 28, 255))
    gold_glow = create_radial_gradient(w, h, (280, 320), 360, (245, 166, 35, 55), (0, 0, 0, 0))
    bg = Image.alpha_composite(bg, gold_glow)
    draw = ImageDraw.Draw(bg)

    if HERO_MASCOT_PATH.exists():
        mascot = Image.open(HERO_MASCOT_PATH).convert("RGBA")
        mascot = mascot.resize((480, 480), Image.Resampling.LANCZOS)
        bg.paste(mascot, (40, 80), mascot)

    fx = 550
    f_badge = get_font(13, bold=True)
    p1, _ = draw_pill(draw, (fx, 90), "MACOS PRODUCTIVITY SUITE", f_badge, outline=C_CYAN, text_color=C_CYAN)
    draw_pill(draw, (p1 + 10, 90), "100% NATIVE SWIFT 6", f_badge, outline=C_GOLD, text_color=C_GOLD)

    f_title = get_font(60, bold=True)
    draw.text((fx, 140), "Khomyak", fill=C_TEXT_WHITE, font=f_title)

    f_slogan = get_font(30, bold=True)
    draw.text((fx, 218), "Tap the Hamster. Own the Flow.", fill=C_GOLD, font=f_slogan)

    f_sub = get_font(18, bold=False)
    draw.text((fx, 268), "Driverless Caps-Lock Hyper-Key & Sub-16ms Multi-App Switcher", fill=C_TEXT_WHITE, font=f_sub)

    f_desc = get_font(15, bold=False)
    lines = [
        "- Tap for Escape (0x35), Hold for Hyper Modifier",
        "- Instant Chrome profile cycling via native macOS Accessibility APIs",
        "- Home-row 5-app switching (Terminal, IDE, AI Agent, Notes, Chrome)",
        "- Universal Linux/X11-style instant Copy-on-Select"
    ]
    dy = 312
    for line in lines:
        draw.text((fx, dy), line, fill=C_TEXT_MUTED, font=f_desc)
        dy += 26

    # Metric boxes
    draw.rounded_rectangle([fx, 440, fx + 670, 510], radius=12, fill=C_CARD_BG, outline=C_BORDER, width=1)
    f_num = get_font(18, bold=True)
    f_lbl = get_font(12, bold=False)

    col_w = 167
    metrics = [
        ("0 ms", "Added Latency", C_CYAN),
        ("15 MB", "RAM Footprint", C_GREEN),
        ("Universal", "Apple Silicon + Intel", C_GOLD),
        ("100% Free", "MIT Open Source", C_TEXT_WHITE)
    ]
    for i, (num, lbl, col) in enumerate(metrics):
        cx = fx + i * col_w + 16
        draw.text((cx, 452), num, fill=col, font=f_num)
        draw.text((cx, 478), lbl, fill=C_TEXT_MUTED, font=f_lbl)
        if i < 3:
            draw.line([fx + (i + 1) * col_w, 452, fx + (i + 1) * col_w, 498], fill=C_BORDER, width=1)

    out = ASSETS_DIR / "khomyak_opengraph_banner.png"
    bg.save(out, "PNG")
    print(f"Generated: {out}")

    site_og = REPO_ROOT / "docs/site/assets/images/khomyak_opengraph_banner.png"
    if site_og.parent.exists():
        bg.save(site_og, "PNG")
        print(f"Generated: {site_og}")

if __name__ == "__main__":
    generate_readme_hero()
    generate_feature_caps_hyper()
    generate_feature_chrome_switch()
    generate_feature_toolkit_switch()
    generate_feature_copy_select()
    generate_opengraph_banner()
    print("All authentic media assets generated successfully!")
