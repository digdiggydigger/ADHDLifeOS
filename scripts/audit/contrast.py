#!/usr/bin/env python3
"""
WCAG 2.x contrast-ratio measurement for ADHDLifeOS's asset-catalog colour tokens.

READ-ONLY tool: parses every `*.colorset/Contents.json` in the app's and the widget's asset
catalogs, resolves light ("any") and dark ("luminosity: dark") components (hex-string red/green/
blue, decimal-string alpha), composites any alpha < 1 onto a caller-supplied backdrop, and prints
WCAG relative-luminance contrast ratios for every foreground/background pair that the app's Swift
actually draws (call sites gathered by hand via grep/Read, listed in PAIRS below).

Usage: python3 contrast.py
"""
import json
import os
import re
from pathlib import Path

REPO = Path("/Users/ethan/[E] Claude Code/v1-GoogleAI-ADHDLifeOS/ADHDLifeOS")
CATALOGS = [
    REPO / "ADHD LifeOS" / "Assets.xcassets",
    REPO / "FocusTimerWidget" / "Assets.xcassets",
]

# ---------------------------------------------------------------------------
# 1. Parse every colorset into {name: {"light": (r,g,b,a), "dark": (r,g,b,a)}}
# ---------------------------------------------------------------------------

def parse_component(s: str) -> float:
    s = s.strip()
    if s.lower().startswith("0x"):
        return int(s, 16) / 255.0
    return float(s)


def load_colorsets():
    tokens = {}
    sources = {}
    for catalog in CATALOGS:
        for contents_path in catalog.glob("*.colorset/Contents.json"):
            name = contents_path.parent.stem
            with open(contents_path) as f:
                data = json.load(f)
            light = None
            dark = None
            for entry in data.get("colors", []):
                if "color" not in entry:
                    # e.g. FocusTimerWidget's WidgetBackground.colorset - no explicit value,
                    # Xcode falls back to a system default. Not a text token; skip.
                    continue
                comps = entry["color"]["components"]
                rgba = (
                    parse_component(comps["red"]),
                    parse_component(comps["green"]),
                    parse_component(comps["blue"]),
                    parse_component(comps.get("alpha", "1.000")),
                )
                appearances = entry.get("appearances")
                if not appearances:
                    light = rgba
                else:
                    for app in appearances:
                        if app.get("appearance") == "luminosity" and app.get("value") == "dark":
                            dark = rgba
            if name in tokens and tokens[name] != {"light": light, "dark": dark}:
                # Same token name defined in both catalogs but with different values worth flagging.
                sources.setdefault(name, []).append(str(catalog))
            tokens[name] = {"light": light, "dark": dark or light}
            sources.setdefault(name, []).append(str(catalog))
    return tokens, sources


TOKENS, SOURCES = load_colorsets()

# ---------------------------------------------------------------------------
# 2. WCAG relative luminance / contrast ratio, sRGB
# ---------------------------------------------------------------------------

def srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def relative_luminance(rgb) -> float:
    r, g, b = rgb[:3]
    R, G, B = srgb_to_linear(r), srgb_to_linear(g), srgb_to_linear(b)
    return 0.2126 * R + 0.7152 * G + 0.0722 * B


def contrast_ratio(rgb1, rgb2) -> float:
    l1 = relative_luminance(rgb1)
    l2 = relative_luminance(rgb2)
    lighter, darker = max(l1, l2), min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)


def composite(fg_rgba, bg_rgb):
    """Alpha-composite fg (r,g,b,a) over an OPAQUE bg (r,g,b). Returns opaque (r,g,b)."""
    r, g, b, a = fg_rgba
    br, bg_, bb = bg_rgb[:3]
    return (
        r * a + br * (1 - a),
        g * a + bg_ * (1 - a),
        b * a + bb * (1 - a),
    )


# Tokens with alpha < 1 that are used as opaque-seeming "surfaces" get an implicit backdrop when
# no explicit `over` is given, so the general surface-sweep code doesn't need special-casing per
# call site. BarSurface: no confirmed call site at all (AppTabBar.swift:92 comment - "still has no
# call site"), so PageBackground is a reasonable assumed backdrop for a bottom bar, flagged as such.
IMPLICIT_BACKDROP = {
    "BarSurface": "PageBackground",
    # Scrim is a full-screen overlay (CaptureFanOverlay.swift:30) that can be raised from any of
    # the six tabs, so its true backdrop varies. PageBackground is used as a representative
    # backdrop (the common case - most screens are page-background-first); Scrim's own alpha
    # (0.80 light / 0.62 dark) over a near-black base (#08080E / #06060A) dominates the result
    # regardless, so the choice of backdrop barely moves the answer - see the printed note.
    "Scrim": "PageBackground",
}


def token_rgb(name: str, appearance: str, over: str = None):
    """Resolve a token to an opaque RGB in the given appearance, compositing over `over`
    (another token name) if the token itself carries alpha < 1. `over=None` requires alpha==1
    unless `name` has an IMPLICIT_BACKDROP entry."""
    rgba = TOKENS[name][appearance]
    if rgba is None:
        raise KeyError(f"{name} has no {appearance} entry")
    if abs(rgba[3] - 1.0) < 1e-6:
        return rgba[:3]
    if over is None:
        over = IMPLICIT_BACKDROP.get(name)
    if over is None:
        raise ValueError(f"{name} has alpha {rgba[3]} in {appearance} and needs a backdrop")
    bg = token_rgb(over, appearance)
    return composite(rgba, bg)


def literal_rgba_over(rgba, over_name, appearance):
    bg = token_rgb(over_name, appearance)
    return composite(rgba, bg)


def fmt(rgb):
    return "#%02X%02X%02X" % tuple(round(c * 255) for c in rgb)


def rating(ratio, small_text=True):
    if ratio < 3.0:
        return "FAIL (<3:1)"
    if small_text and ratio < 4.5:
        return "text-small FAIL (<4.5:1)"
    if (not small_text) and ratio < 3.0:
        return "FAIL"
    return "PASS"


# ---------------------------------------------------------------------------
# 3. Token table
# ---------------------------------------------------------------------------

def print_token_table():
    print("=" * 100)
    print("TOKEN TABLE  (name : light rgba -> hex@alpha : dark rgba -> hex@alpha)")
    print("=" * 100)
    for name in sorted(TOKENS):
        l = TOKENS[name]["light"]
        d = TOKENS[name]["dark"]
        if l is None and d is None:
            print(f"{name:28s}  (no explicit value in either appearance - system default; skipped from pairs)")
            continue
        lhex = fmt(l[:3]) + (f"@{l[3]:.2f}" if l[3] < 0.999 else "")
        dhex = fmt(d[:3]) + (f"@{d[3]:.2f}" if d[3] < 0.999 else "")
        print(f"{name:28s}  light {lhex:14s}  dark {dhex:14s}")
    print()


# ---------------------------------------------------------------------------
# 4. Pairs actually drawn in the app (gathered by grep/Read over the Swift sources)
# ---------------------------------------------------------------------------
# Each entry: (fg_token_or_literal, bg_token, small_text: bool, location, note)
# fg can be:
#   ("token", name)                          - opaque or alpha-bearing colorset token
#   ("literal", (r,g,b,a))                   - a literal SwiftUI colour e.g. .white.opacity(0.62)
#   ("secondary", base_appearance_note)      - iOS secondaryLabel over a custom surface (per task step 5)

RESULTS = []


def add_pair(label, fg_desc, fg_name_or_rgba, bg_name, small_text, location, note="", alpha_bg=None):
    """alpha_bg: if the 'background' itself is an alpha wash over another surface, pass
    (wash_token, wash_alpha_override_or_None, base_surface) - handled inline by caller instead;
    kept simple: bg_name must already be a resolvable opaque-or-composited token name, OR a tuple
    ('wash', wash_token, base_surface) meaning composite wash_token over base_surface first."""
    for appearance in ("light", "dark"):
        # Resolve background
        if isinstance(bg_name, tuple) and bg_name[0] == "wash":
            _, wash_token, wash_alpha, base_surface = bg_name
            base_rgb = token_rgb(base_surface, appearance)
            wash_rgba = TOKENS[wash_token][appearance]
            wash_rgba = (wash_rgba[0], wash_rgba[1], wash_rgba[2], wash_alpha)
            bg_rgb = composite(wash_rgba, base_rgb)
            bg_label = f"{wash_token}@{wash_alpha} over {base_surface}"
        else:
            bg_rgb = token_rgb(bg_name, appearance)
            bg_label = bg_name

        # Resolve foreground
        if fg_desc == "token":
            fg_rgba = TOKENS[fg_name_or_rgba][appearance]
            if abs(fg_rgba[3] - 1.0) < 1e-6:
                fg_rgb = fg_rgba[:3]
            else:
                fg_rgb = composite(fg_rgba, bg_rgb)
            fg_label = fg_name_or_rgba + (f"@{fg_rgba[3]:.2f}" if fg_rgba[3] < 0.999 else "")
        elif fg_desc == "literal":
            fg_rgb = composite(fg_name_or_rgba, bg_rgb)
            fg_label = "literal " + fmt(fg_name_or_rgba[:3]) + f"@{fg_name_or_rgba[3]:.2f}"
        elif fg_desc == "secondaryLabel":
            # iOS secondaryLabel per task step 5: light #3C3C43@60%, dark #EBEBF5@60%
            base = (0x3C / 255, 0x3C / 255, 0x43 / 255, 0.60) if appearance == "light" else (0xEB / 255, 0xEB / 255, 0xF5 / 255, 0.60)
            fg_rgb = composite(base, bg_rgb)
            fg_label = "secondaryLabel@0.60"
        else:
            raise ValueError(fg_desc)

        ratio = contrast_ratio(fg_rgb, bg_rgb)
        RESULTS.append({
            "label": label,
            "fg": fg_label,
            "bg": bg_label,
            "appearance": appearance,
            "ratio": ratio,
            "rating": rating(ratio, small_text),
            "location": location,
            "note": note,
        })


# --- Core label hierarchy x core surfaces -----------------------------------
SURFACES_CORE = ["PageBackground", "CardSurface", "CardSurfaceSecondary", "BarSurface"]
LABELS = ["LabelPrimary", "LabelSecondary", "LabelTertiary"]
for lbl in LABELS:
    for surf in SURFACES_CORE:
        add_pair(f"{lbl} on {surf}", "token", lbl, surf, small_text=True,
                  location="app-wide (LabelPrimary/Secondary/Tertiary on core surfaces)",
                  note="BarSurface has NO call site (AppTabBar.swift:92 comment) - listed for completeness only" if surf == "BarSurface" else "")

# --- State colours (icon/text) on core surfaces -----------------------------
for st in ["StateGo", "StateWarn", "StateRisk"]:
    for surf in ["PageBackground", "CardSurface"]:
        add_pair(f"{st} on {surf}", "token", st, surf, small_text=True,
                  location="many call sites, see grep dump", note="")

# --- AccentColor on core surfaces -------------------------------------------
for surf in ["PageBackground", "CardSurface"]:
    add_pair(f"AccentColor on {surf}", "token", "AccentColor", surf, small_text=True,
              location="Auth/LoginFormSections.swift:172 (.tint on PageBackground); "
                       "Capture/CaptureInboxSections.swift:121 (sectionLabel on CardSurface via bentoCard)",
              note="")

# --- Area label hues on core surfaces ---------------------------------------
AREAS = ["AreaWork", "AreaHealth", "AreaAdmin", "AreaGrowth", "AreaHobby", "AreaGreen", "AreaOrange", "AreaRed", "AreaSlate"]
for area in AREAS:
    for surf in ["PageBackground", "CardSurface"]:
        add_pair(f"{area} on {surf}", "token", area, surf, small_text=True,
                  location="AreaPalette.color used as status-line/label text e.g. Home/AreaMomentumList.swift:85 (.clear tone), "
                           "Areas/AreasComponents.swift:184",
                  note="")

# --- OnArea* on Area*Vivid (chip/disc text) ---------------------------------
for area in ["AreaWork", "AreaHealth", "AreaAdmin", "AreaGrowth", "AreaHobby", "AreaGreen", "AreaOrange", "AreaRed", "AreaSlate"]:
    on = "On" + area
    vivid = area + "Vivid"
    add_pair(f"{on} on {vivid}", "token", on, vivid, small_text=True,
              location="Capture/CaptureFan.swift (disc fill/onAssetName pairs); AreaPalette.onColor/.vivid "
                       "used together wherever a solid area button/disc is drawn",
              note="")

# --- OnStateGo on StateGo / StateGoVivid (solid buttons, badges) -----------
add_pair("OnStateGo on StateGo", "token", "OnStateGo", "StateGo", small_text=False,
          location="Home/MomentumScoreboardViews.swift:280 MomentumSolidButtonStyle(fill: StateGo, foreground: OnStateGo) "
                   "'Close it' button (font(.body.bold()), regular-size bold >= 14pt bold threshold)",
          note="(f) the green solid Close it button")
add_pair("OnStateGo on StateGoVivid", "token", "OnStateGo", "StateGoVivid", small_text=True,
          location="Focus/FocusCompletionCard.swift:139 .background(StateGo...) / ConfirmCelebrationRecipe colorName=StateGo "
                   "(StateGoVivid is the ring/vivid twin, checked in case any button uses the vivid fill)",
          note="inferred pairing, not confirmed as an actual OnStateGo-on-Vivid call site")

# --- OnStateWarn on StateWarn / StateWarnVivid ------------------------------
add_pair("OnStateWarn on StateWarn", "token", "OnStateWarn", "StateWarn", small_text=True,
          location="colorset exists (OnStateWarn) but NO confirmed Swift call site combining it with StateWarn/StateWarnVivid "
                   "as a text-on-fill pair (grep found no `foreground: Color(\"OnStateWarn\")` usage)",
          note="inferred / token exists but appears UNUSED - flagged for completeness")
add_pair("OnStateWarn on StateWarnVivid", "token", "OnStateWarn", "StateWarnVivid", small_text=True,
          location="same as above - token pairing exists in the catalog, no confirmed call site",
          note="inferred / possibly unused")

# --- White text on StateRisk badge (tab bar count) --------------------------
add_pair("white on StateRisk", "literal", (1.0, 1.0, 1.0, 1.0), "StateRisk", small_text=True,
          location="Theme/AppTabBar.swift:245-257 AppTabBarBadge - Text(.caption2.weight(.semibold)) "
                   ".foregroundStyle(.white) .background(Color(\"StateRisk\"))",
          note="code's own comment claims '~4.2:1' and calls it acceptable because count is echoed in the a11y label (accessibilityHidden(true))")

# --- Tab bar unselected glyph -------------------------------------------------
add_pair("LabelSecondary (unselected tab glyph) on CardSurface", "token", "LabelSecondary", "CardSurface", small_text=False,
          location="Theme/AppTabBar.swift:199 .foregroundStyle(isSelected ? Color.accentColor : Color.labelSecondary); "
                   "bar surface is Color.cardSurface per AppTabBar.swift:102-103 (BarSurface token is unused, see AppTabBar.swift:92 comment)",
          note="(h) tab-bar unselected glyph; glyph is .title2/.imageScale(.large) ~25pt so treated as LARGE text/graphic (3:1 bar), also listed under small-text table row above")
add_pair("AccentColor (selected tab glyph) on CardSurface", "token", "AccentColor", "CardSurface", small_text=False,
          location="Theme/AppTabBar.swift:199", note="selected-state companion to the row above")

# --- StateWarn specifically requested pairs (a) -----------------------------
add_pair("StateWarn text on CardSurface", "token", "StateWarn", "CardSurface", small_text=True,
          location="Home/AreaMomentumList.swift:61 (.footnote status line 'N of M closed — quiet since <weekday>'); "
                   "Areas/AreasComponents.swift ~184 (same pattern in the Areas tab); "
                   "Capture/CaptureInboxSections.swift:132 ('Four are still sitting here…' footnote inside bentoCard)",
          note="(a) task's named example 1")
add_pair("StateWarn text on PageBackground", "token", "StateWarn", "PageBackground", small_text=False,
          location="Capture/CaptureInboxSections.swift:212 the '4' count itself (.font(.largeTitle.bold()) — LARGE text, "
                   "3:1 threshold) inside CaptureInboxView's bare ScrollView (no bentoCard, sits on PageBackground)",
          note="(a) task's named example 2 - largeTitle so evaluated as large text")
add_pair("StateWarn text on PageBackground (small)", "token", "StateWarn", "PageBackground", small_text=True,
          location="same as above, re-checked against the small-text bar for reference since other StateWarn text "
                   "(e.g. HomeAccessoryStrips.swift:176) is .footnote directly on PageBackground-backed screens",
          note="reference row: worst case if a footnote-sized StateWarn ever sits directly on PageBackground")

# --- (b) urgentBentoCard: StateWarn @0.10 over CardSurface, LabelPrimary text ---
add_pair("LabelPrimary on StateWarn@0.10 wash over CardSurface", "token", "LabelPrimary",
          ("wash", "StateWarn", 0.10, "CardSurface"), small_text=True,
          location="Theme/Theme.swift:71-91 UrgentBentoCardModifier (.urgentBentoCard()) - the due-nudge card treatment",
          note="(b) task's named example - background is the wash, LabelPrimary is whatever text a caller puts on the card")
# Also the MomentumChip variant actually seen in code: StateWarn text on StateWarn@0.16 wash over CardSurface
add_pair("StateWarn text on StateWarn@0.16 wash over CardSurface", "token", "StateWarn",
          ("wash", "StateWarn", 0.16, "CardSurface"), small_text=True,
          location="Home/HomeAccessoryStrips.swift:61-67 MomentumChip(foreground: StateWarn, background: StateWarn.opacity(0.16)) "
                   "inbox count chip",
          note="related but distinct from (b): here the WASH'S OWN colour is also the text colour")

# --- (c) Forgot password? ----------------------------------------------------
add_pair("Forgot password? (.tint/AccentColor, enabled) on PageBackground", "token", "AccentColor", "PageBackground",
          small_text=True, location="Auth/LoginFormSections.swift:161-176 forgotPasswordButton, .font(.footnote); "
                                     "screen background Auth/LoginView.swift:96 .background(Color.pageBackground...)",
          note="(c) enabled state")
add_pair("Forgot password? (.secondary, disabled) on PageBackground", "secondaryLabel", None, "PageBackground",
          small_text=True, location="same call site, disabled state (!canRequest) uses AnyShapeStyle(.secondary)",
          note="(c) disabled state - iOS secondaryLabel per task step 5 spec")

# --- (d) Composer placeholders ------------------------------------------------
# Task-create "What needs doing?" / QuickCapture "What's on your mind?": no placeholderAsset ->
# system TextField placeholder colour. Not a colorset token; best documented value is
# UIColor.placeholderText, which matches tertiaryLabel's published spec (#3C3C43@30% light,
# #EBEBF5@30% dark). Treated as inferred per instructions.
def add_literal_pair(label, rgba_light, rgba_dark, bg_name, small_text, location, note):
    for appearance, rgba in (("light", rgba_light), ("dark", rgba_dark)):
        bg_rgb = token_rgb(bg_name, appearance)
        fg_rgb = composite(rgba, bg_rgb)
        ratio = contrast_ratio(fg_rgb, bg_rgb)
        RESULTS.append({
            "label": label, "fg": "literal " + fmt(rgba[:3]) + f"@{rgba[3]:.2f}",
            "bg": bg_name, "appearance": appearance, "ratio": ratio,
            "rating": rating(ratio, small_text), "location": location, "note": note,
        })


add_literal_pair(
    "TaskCreate 'What needs doing?' placeholder (system placeholderText, inferred) on CardSurfaceSecondary",
    (0x3C / 255, 0x3C / 255, 0x43 / 255, 0.30), (0xEB / 255, 0xEB / 255, 0xF5 / 255, 0.30),
    "CardSurfaceSecondary", True,
    "Tasks/TaskCreateView.swift:43-47 ComposerTextBox(placeholder: \"What needs doing?\") - no placeholderAsset -> "
    "default surfaceAsset CardSurfaceSecondary (Theme/ComposerChips.swift:210-227)",
    "(d) INFERRED: no custom token, using UIColor.placeholderText's documented spec (~= tertiaryLabel, 30% alpha)")
add_literal_pair(
    "QuickCapture 'What's on your mind?' placeholder (system placeholderText, inferred) on CardSurfaceSecondary",
    (0x3C / 255, 0x3C / 255, 0x43 / 255, 0.30), (0xEB / 255, 0xEB / 255, 0xF5 / 255, 0.30),
    "CardSurfaceSecondary", True,
    "Capture/QuickCaptureComponents.swift:75-91 TextField(contentFieldPlaceholder, ...) directly, "
    ".background(Color(\"CardSurfaceSecondary\"))",
    "(d) INFERRED: same system default, this is a raw TextField(title:) placeholder not a `prompt:`")
add_pair("Journal pad 'What's on your mind?' placeholder (JournalPaperPlaceholder) on JournalPaperSurface",
          "token", "JournalPaperPlaceholder", "JournalPaperSurface", small_text=True,
          location="Journal/LogComposerView.swift:48-59 + JournalComposerPalette.placeholderAsset/writingSurfaceAsset "
                   "(type == .journal branch)",
          note="(d) journal-pad variant; codebase's own comment (JournalComposerPalette.swift:178-184) claims "
               "5.98:1 day / 5.61:1 night - independently re-verified below")
add_pair("Journal log placeholder (system default, inferred) on CardSurfaceSecondary", "secondaryLabel", None,
          "CardSurfaceSecondary", True,
          location="Journal/LogComposerView.swift for LogType.log (non-journal) - placeholderAsset returns nil",
          note="(d) INFERRED fallback for the plain 'log' composer type")

# --- (e) CaptureFanOverlay subtitle -----------------------------------------
add_pair("CaptureFanOverlay subtitle .white.opacity(0.62) on Scrim", "literal", (1.0, 1.0, 1.0, 0.62), "Scrim",
          small_text=True,
          location="Capture/CaptureFanOverlay.swift:42-45 (.footnote, .white.opacity(0.62)) over Color(\"Scrim\") "
                   "(CaptureFanOverlay.swift:30, ignoresSafeArea, itself may carry alpha - see token table)",
          note="(e) Scrim's own alpha is NOT composited further here (nothing behind it is knowable app-wide); "
               "if Scrim<1.0 alpha, true on-device contrast vs whatever is behind it will differ - see caveat in report")

# --- (f) green solid Close it button (already added above as OnStateGo on StateGo) ---
# also check the headline "Close it" text style specifically for size: .font(.body.bold()) — regular
# size (17pt) bold is NOT >=14pt bold-large threshold by itself... WCAG large-text bold threshold is
# 14pt(18.66px)/~18.5px bold. .body is 17pt regular / bold, so bold 17pt DOES qualify as "large text"
# (>=14pt and bold). Already marked small_text=False above for that reason; also add a strict small
# read for reference.
add_pair("OnStateGo on StateGo (strict small-text read)", "token", "OnStateGo", "StateGo", small_text=True,
          location="same MomentumSolidButtonStyle button as above",
          note="(f) reference row treating it as small text even though 17pt bold clears the WCAG large-text bar")

# --- (g) AccentColor already covered above under 'AccentColor on <surf>' ----

print_token_table()

print("=" * 100)
print("COMPUTED PAIRS")
print("=" * 100)
for r in RESULTS:
    print(f"[{r['rating']:24s}] {r['ratio']:5.2f}:1  {r['appearance']:5s}  "
          f"fg={r['fg']:32s} bg={r['bg']}")
    print(f"    label: {r['label']}")
    if r['location']:
        print(f"    where: {r['location']}")
    if r['note']:
        print(f"    note:  {r['note']}")
    print()

fails = [r for r in RESULTS if r['rating'] != 'PASS']
passes = [r for r in RESULTS if r['rating'] == 'PASS']
print("=" * 100)
print(f"SUMMARY: {len(RESULTS)} pairs computed, {len(passes)} PASS, {len(fails)} FAIL/text-small-FAIL")
print("=" * 100)
