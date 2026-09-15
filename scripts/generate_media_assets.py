#!/usr/bin/env python3
"""
scripts/generate_media_assets.py
Generates high-resolution, neuroaesthetics-grounded brand media assets for Khomyak:
1. README Hero Banner (1200x480)
2. OpenGraph / GitHub Social Preview (1280x640)
3. Custom DMG Installer Window Background (600x400)
4. 4 Feature Infographic Cards (800x450 each)
"""

import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

REPO_ROOT = Path("/Users/igorekishev/Igor/igorekishev/mac-productivity-suite")
ASSETS_DIR = REPO_ROOT / "assets"
FEATURES_DIR = ASSETS_DIR / "features"
ASSETS_DIR.mkdir(parents=True, exist_ok=True)
FEATURES_DIR.mkdir(parents=True, exist_ok=True)

APP_ICON_PATH = REPO_ROOT / "src/ChromeQuickAccess/Resources/AppIcon.png"
if not APP_ICON_PATH.exists():
    APP_ICON_PATH = Path("/Users/igorekishev/.gemini/antigravity/brain/8f5160ea-d58a-4d8d-8180-ba84e1269aaf/khomyak_high_contrast_2_1789435199593.jpg")

# Neuroaesthetic Brand Color Tokens
C_MIDNIGHT = (11, 17, 32)        # #0B1120
C_NAVY_DARK = (6, 11, 24)        # #060B18
C_CARD_BG = (18, 26, 46)         # #121A2E
C_GOLD = (245, 166, 35)          # #F5A623
C_GOLD_LIGHT = (255, 215, 100)   # #FFD764
C_CREAM = (255, 244, 224)        # #FFF4E0
C_CYAN = (56, 189, 248)          # #38BDF8
C_CYAN_GLOW = (224, 242, 254)    # #E0F2FE
C_BORDER = (38, 52, 85)          # #263455
C_TEXT_WHITE = (248, 250, 252)   # #F8FAFC
C_TEXT_MUTED = (148, 163, 184)   # #94A3B8
C_GREEN = (52, 211, 153)         # #34D399
C_PURPLE = (168, 85, 247)        # #A855F7

def get_font(size: int = 24, bold: bool = True):
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/SFNS.ttf",
        "/Library/Fonts/Arial Bold.ttf" if bold else "/Library/Fonts/Arial.ttf",
    ]
    for c in candidates:
        if Path(c).exists():
            try:
                return ImageFont.truetype(c, size)
            except Exception:
                continue
    return ImageFont.load_default()

def draw_pill(draw, xy, text, font, fill=C_CARD_BG, outline=C_CYAN, text_color=C_CYAN, radius=12, pad_x=14, pad_y=6):
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
    """Creates a smooth radial gradient surface."""
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
# 1. README Hero Banner (1200x480)
# -------------------------------------------------------------
def generate_readme_hero():
    w, h = 1200, 480
    bg = create_radial_gradient(w, h, (320, 240), 450, (24, 38, 72, 255), (11, 17, 32, 255))
    
    warm_glow = create_radial_gradient(w, h, (240, 240), 280, (245, 166, 35, 45), (0, 0, 0, 0))
    bg = Image.alpha_composite(bg, warm_glow)
    
    draw = ImageDraw.Draw(bg)
    
    # Load and place Mascot AppIcon
    icon = Image.open(APP_ICON_PATH).convert("RGBA")
    icon = icon.resize((360, 360), Image.Resampling.LANCZOS)
    bg.paste(icon, (50, 60), icon)
    
    fx = 460
    font_badge = get_font(13, bold=True)
    p1_x, _ = draw_pill(draw, (fx, 58), "PURE SWIFT 6", font_badge, fill=(15, 23, 42, 220), outline=(56, 189, 248), text_color=C_CYAN)
    p2_x, _ = draw_pill(draw, (p1_x + 10, 58), "ZERO DAEMONS", font_badge, fill=(15, 23, 42, 220), outline=(52, 211, 153), text_color=C_GREEN)
    draw_pill(draw, (p2_x + 10, 58), "SUB-16MS FLOW", font_badge, fill=(15, 23, 42, 220), outline=(245, 166, 35), text_color=C_GOLD)
    
    font_title = get_font(52, bold=True)
    draw.text((fx, 102), "KHOMYAK", fill=C_TEXT_WHITE, font=font_title)
    
    font_slogan = get_font(26, bold=True)
    draw.text((fx, 170), "Tap the Hamster. Own the Flow.", fill=C_GOLD, font=font_slogan)
    
    font_desc = get_font(16, bold=False)
    desc_lines = [
        "The driverless macOS hyper-key that transforms your physical Caps Lock",
        "into an instantaneous workspace switch for Chrome profiles, Terminal, IDE,",
        "AI agents, and universal Linux-style Copy-on-Select."
    ]
    dy = 216
    for line in desc_lines:
        draw.text((fx, dy), line, fill=C_TEXT_MUTED, font=font_desc)
        dy += 24
        
    card_y = 310
    draw.rounded_rectangle([fx, card_y, fx + 680, card_y + 115], radius=14, fill=(16, 24, 44, 230), outline=C_BORDER, width=1)
    
    font_key_header = get_font(12, bold=True)
    draw.text((fx + 18, card_y + 12), "TACTILE HOME-ROW CONTROLS", fill=C_CYAN, font=font_key_header)
    
    font_key = get_font(15, bold=True)
    font_action = get_font(14, bold=False)
    
    draw_pill(draw, (fx + 18, card_y + 38), "⇪ Tap Alone", font_key, fill=(30, 41, 68), outline=C_CYAN, text_color=C_TEXT_WHITE, pad_x=10, pad_y=4)
    draw.text((fx + 140, card_y + 44), "➔ Synthesizes Escape (Vim, Modals)", fill=C_TEXT_MUTED, font=font_action)
    
    draw_pill(draw, (fx + 410, card_y + 38), "⇪ Hold", font_key, fill=(30, 41, 68), outline=C_PURPLE, text_color=C_TEXT_WHITE, pad_x=10, pad_y=4)
    draw.text((fx + 485, card_y + 44), "➔ Hyper Modifier", fill=C_TEXT_MUTED, font=font_action)
    
    draw_pill(draw, (fx + 18, card_y + 74), "⇪ + C", font_key, fill=(30, 41, 68), outline=C_GOLD, text_color=C_GOLD_LIGHT, pad_x=10, pad_y=4)
    draw.text((fx + 95, card_y + 80), "➔ Cycle Chrome Profiles", fill=C_TEXT_MUTED, font=font_action)
    
    draw_pill(draw, (fx + 285, card_y + 74), "⇪ + T / I / A / N", font_key, fill=(30, 41, 68), outline=C_GREEN, text_color=C_GREEN, pad_x=10, pad_y=4)
    draw.text((fx + 425, card_y + 80), "➔ Instant 5-App Switch", fill=C_TEXT_MUTED, font=font_action)

    out_path = ASSETS_DIR / "khomyak_readme_hero.png"
    bg.save(out_path, "PNG")
    print(f"✅ Generated: {out_path}")

# -------------------------------------------------------------
# 2. OpenGraph / Social Share Preview (1280x640)
# -------------------------------------------------------------
def generate_opengraph_banner():
    w, h = 1280, 640
    bg = create_radial_gradient(w, h, (360, 320), 550, (28, 44, 84, 255), (10, 15, 28, 255))
    
    warm_glow = create_radial_gradient(w, h, (280, 320), 320, (245, 166, 35, 55), (0, 0, 0, 0))
    bg = Image.alpha_composite(bg, warm_glow)
    draw = ImageDraw.Draw(bg)
    
    icon = Image.open(APP_ICON_PATH).convert("RGBA")
    icon = icon.resize((440, 440), Image.Resampling.LANCZOS)
    bg.paste(icon, (70, 100), icon)
    
    fx = 560
    font_badge = get_font(14, bold=True)
    p1_x, _ = draw_pill(draw, (fx, 110), "MACOS PRODUCTIVITY SUITE", font_badge, fill=(15, 23, 42, 220), outline=C_CYAN, text_color=C_CYAN)
    draw_pill(draw, (p1_x + 12, 110), "100% NATIVE SWIFT 6", font_badge, fill=(15, 23, 42, 220), outline=C_GOLD, text_color=C_GOLD)
    
    font_title = get_font(64, bold=True)
    draw.text((fx, 160), "KHOMYAK", fill=C_TEXT_WHITE, font=font_title)
    
    font_slogan = get_font(32, bold=True)
    draw.text((fx, 244), "Tap the Hamster. Own the Flow.", fill=C_GOLD, font=font_slogan)
    
    font_sub = get_font(20, bold=False)
    draw.text((fx, 296), "Driverless Caps-Lock Hyper-Key & Multi-App Switcher", fill=C_TEXT_WHITE, font=font_sub)
    
    font_desc = get_font(17, bold=False)
    lines = [
        "• Tap for Escape, Hold for Hyper Modifier (0x35 synthesis)",
        "• Instant Chrome profile cycling via native Accessibility APIs",
        "• Zero-latency 5-app switching (Terminal, IDE, AI, Notes, Chrome)",
        "• Universal Linux/X11-style instant Copy-on-Select"
    ]
    dy = 345
    for line in lines:
        draw.text((fx, dy), line, fill=C_TEXT_MUTED, font=font_desc)
        dy += 30
        
    draw.rounded_rectangle([fx, 500, fx + 640, 565], radius=12, fill=(18, 26, 46, 240), outline=C_BORDER, width=1)
    font_metric_num = get_font(18, bold=True)
    font_metric_lbl = get_font(13, bold=False)
    
    draw.text((fx + 25, 512), "0 ms", fill=C_CYAN, font=font_metric_num)
    draw.text((fx + 25, 536), "Added Latency", fill=C_TEXT_MUTED, font=font_metric_lbl)
    
    draw.line([fx + 160, 515, fx + 160, 550], fill=C_BORDER, width=1)
    draw.text((fx + 185, 512), "0 MB", fill=C_GREEN, font=font_metric_num)
    draw.text((fx + 185, 536), "Electron Bloat", fill=C_TEXT_MUTED, font=font_metric_lbl)
    
    draw.line([fx + 325, 515, fx + 325, 550], fill=C_BORDER, width=1)
    draw.text((fx + 350, 512), "Universal", fill=C_GOLD, font=font_metric_num)
    draw.text((fx + 350, 536), "Apple Silicon + Intel", fill=C_TEXT_MUTED, font=font_metric_lbl)
    
    draw.line([fx + 490, 515, fx + 490, 550], fill=C_BORDER, width=1)
    draw.text((fx + 515, 512), "MIT", fill=C_TEXT_WHITE, font=font_metric_num)
    draw.text((fx + 515, 536), "Open Source", fill=C_TEXT_MUTED, font=font_metric_lbl)

    out_path = ASSETS_DIR / "khomyak_opengraph_banner.png"
    bg.save(out_path, "PNG")
    print(f"✅ Generated: {out_path}")

# -------------------------------------------------------------
# 3. Custom DMG Installer Background (600x400)
# -------------------------------------------------------------
def generate_dmg_background():
    w, h = 600, 400
    bg = create_radial_gradient(w, h, (300, 200), 380, (22, 34, 64, 255), (8, 12, 22, 255))
    draw = ImageDraw.Draw(bg)
    
    font_title = get_font(26, bold=True)
    font_sub = get_font(13, bold=False)
    
    bbox = draw.textbbox((0, 0), "Khomyak", font=font_title)
    tw = bbox[2] - bbox[0]
    draw.text(((w - tw) // 2, 35), "Khomyak", fill=C_TEXT_WHITE, font=font_title)
    
    sub_text = "Drag Khomyak to Applications to install"
    sbbox = draw.textbbox((0, 0), sub_text, font=font_sub)
    stw = sbbox[2] - sbbox[0]
    draw.text(((w - stw) // 2, 70), sub_text, fill=C_CYAN, font=font_sub)
    
    app_cx, app_cy = 150, 210
    draw.ellipse([app_cx - 65, app_cy - 65, app_cx + 65, app_cy + 65], outline=(38, 52, 85), width=2)
    draw.text((app_cx - 36, app_cy + 75), "Khomyak.app", fill=C_TEXT_MUTED, font=font_sub)
    
    app_rx, app_ry = 450, 210
    draw.ellipse([app_rx - 65, app_ry - 65, app_rx + 65, app_ry + 65], outline=(38, 52, 85), width=2)
    draw.text((app_rx - 34, app_ry + 75), "Applications", fill=C_TEXT_MUTED, font=font_sub)
    
    arrow_y = 210
    draw.line([app_cx + 80, arrow_y, app_rx - 80, arrow_y], fill=C_CYAN, width=4)
    ax = app_rx - 80
    draw.polygon([(ax, arrow_y - 12), (ax + 16, arrow_y), (ax, arrow_y + 12)], fill=C_CYAN)
    
    font_arrow_lbl = get_font(12, bold=True)
    albl = "Tap the Hamster. Own the Flow."
    abbox = draw.textbbox((0, 0), albl, font=font_arrow_lbl)
    atw = abbox[2] - abbox[0]
    draw.text(((w - atw) // 2, arrow_y + 14), albl, fill=C_GOLD, font=font_arrow_lbl)
    
    font_footer = get_font(11, bold=False)
    footer_text = "Requires macOS 14.0 Sonoma or newer • Universal arm64 & x86_64"
    fb = draw.textbbox((0, 0), footer_text, font=font_footer)
    draw.text(((w - (fb[2] - fb[0])) // 2, 360), footer_text, fill=(100, 116, 139), font=font_footer)

    out_path = ASSETS_DIR / "dmg_background.png"
    bg.save(out_path, "PNG")
    print(f"✅ Generated: {out_path}")
    
    res_path = REPO_ROOT / "src/ChromeQuickAccess/Resources/dmg_background.png"
    bg.save(res_path, "PNG")
    print(f"✅ Saved to: {res_path}")

# -------------------------------------------------------------
# 4. Feature Diagram Cards (800x450 each)
# -------------------------------------------------------------
def generate_feature_cards():
    cards = [
        {
            "id": "feature_caps_hyper",
            "title": "Dual-Role Caps-Lock Hyper Key",
            "badge": "HARDWARE REMAP",
            "badge_color": C_CYAN,
            "subtitle": "Eliminate the useless Caps-Lock key. Single tap for Escape, hold for Hyper.",
            "points": [
                ("Tap Alone (<200ms)", "Emits Escape (0x35) — Instant Vim/Terminal command escape & modal exit"),
                ("Hold Down", "Acts as Hyper (Shift + Control + Option + Command) with zero LED toggles"),
                ("Driverless CoreGraphics", "Native CGEventTap & IOHID — No Karabiner or kernel extensions required")
            ],
            "key_accent": "⇪"
        },
        {
            "id": "feature_chrome_switch",
            "title": "Google Chrome Multi-Profile Switcher",
            "badge": "PROFILE SWITCH",
            "badge_color": C_GOLD,
            "subtitle": "Switch between Work, Personal, and Dev Chrome windows in zero milliseconds.",
            "points": [
                ("Caps-Lock + C", "Instantly cycles focus across all open Chrome profile windows"),
                ("Caps-Lock + 1..4", "Direct jump to specific profile slot via number keys"),
                ("Native Accessibility API", "Focuses existing windows with zero unwanted empty tabs or AppleScript delay")
            ],
            "key_accent": "C"
        },
        {
            "id": "feature_toolkit_switch",
            "title": "5-App Toolkit Ecosystem",
            "badge": "APP ORCHESTRATION",
            "badge_color": C_GREEN,
            "subtitle": "Instant keyboard routing between your 5 primary developer power tools.",
            "points": [
                ("Caps + T ➔ Terminal", "Direct focus to iTerm2, Ghostty, Alacritty, or Terminal"),
                ("Caps + I ➔ IDE", "Instant focus to VS Code, Xcode, Cursor, or JetBrains"),
                ("Caps + A / N ➔ AI & Notes", "Instant focus to Claude, ChatGPT, Obsidian, or Apple Notes")
            ],
            "key_accent": "T/I/A"
        },
        {
            "id": "feature_copy_select",
            "title": "Universal Linux/X11 Copy-on-Select",
            "badge": "SELECTION ERGONOMICS",
            "badge_color": C_PURPLE,
            "subtitle": "Highlight text anywhere in macOS — it's automatically copied to the clipboard.",
            "points": [
                ("Mouse Drag Selection", "Copies highlighted text instantly upon releasing drag (>10pt distance)"),
                ("Multi-Click Selection", "Double-click a word or triple-click a paragraph to copy immediately"),
                ("System-Wide & Driverless", "Works across browsers, editors, PDF viewers, and terminals with zero bloat")
            ],
            "key_accent": "⌘C"
        }
    ]
    
    for c in cards:
        w, h = 800, 450
        bg = create_radial_gradient(w, h, (400, 225), 450, (20, 30, 56, 255), (10, 15, 28, 255))
        draw = ImageDraw.Draw(bg)
        
        draw.rounded_rectangle([16, 16, w - 16, h - 16], radius=16, outline=C_BORDER, width=2)
        
        font_badge = get_font(12, bold=True)
        draw_pill(draw, (36, 36), c["badge"], font_badge, fill=(15, 23, 42, 220), outline=c["badge_color"], text_color=c["badge_color"])
        
        font_title = get_font(28, bold=True)
        draw.text((36, 75), c["title"], fill=C_TEXT_WHITE, font=font_title)
        
        font_sub = get_font(15, bold=False)
        draw.text((36, 116), c["subtitle"], fill=C_TEXT_MUTED, font=font_sub)
        
        draw.line([36, 148, w - 36, 148], fill=C_BORDER, width=1)
        
        dy = 168
        font_bhead = get_font(16, bold=True)
        font_bdesc = get_font(14, bold=False)
        for head, desc in c["points"]:
            draw.rounded_rectangle([36, dy, w - 36, dy + 62], radius=10, fill=(16, 24, 44, 200), outline=(28, 40, 68), width=1)
            draw.ellipse([54, dy + 22, 64, dy + 32], fill=c["badge_color"])
            draw.text((76, dy + 12), head, fill=C_TEXT_WHITE, font=font_bhead)
            draw.text((76, dy + 34), desc, fill=C_TEXT_MUTED, font=font_bdesc)
            dy += 74
            
        kw, kh = 84, 84
        kx, ky = w - 120, 36
        draw.rounded_rectangle([kx, ky, kx + kw, ky + kh], radius=14, fill=(28, 38, 66), outline=c["badge_color"], width=2)
        font_key_icon = get_font(28, bold=True)
        kb = draw.textbbox((0, 0), c["key_accent"], font=font_key_icon)
        draw.text((kx + (kw - (kb[2] - kb[0])) // 2, ky + (kh - (kb[3] - kb[1])) // 2 - 2), c["key_accent"], fill=C_TEXT_WHITE, font=font_key_icon)

        out_path = FEATURES_DIR / f"{c['id']}.png"
        bg.save(out_path, "PNG")
        print(f"✅ Generated: {out_path}")

if __name__ == "__main__":
    generate_readme_hero()
    generate_opengraph_banner()
    generate_dmg_background()
    generate_feature_cards()
    print("🎉 All application brand media assets generated successfully!")
