"""
Generate docs/workflow-demo.gif — stylized workflow (not a screen recording).
Run: python scripts/generate_workflow_demo_gif.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

try:
    import imageio.v2 as imageio
except ImportError:
    raise SystemExit("pip install pillow imageio")

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "workflow-demo.gif"

FONT_LG = FONT_MD = FONT_SM = ImageFont.load_default()

W, H = 720, 405
FPS = 5
HOLD = int(FPS * 3.5)

# Neon / saturated palette helpers
RAINBOW = (
    "#ff0055",
    "#ff6600",
    "#ffee00",
    "#00ff88",
    "#00ccff",
    "#6644ff",
    "#ff00cc",
)


def try_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for name in ("segoeui.ttf", "arial.ttf", "calibri.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def _lerp_rgb(
    c0: tuple[int, int, int], c1: tuple[int, int, int], u: float
) -> tuple[int, int, int]:
    return (
        int(c0[0] * (1 - u) + c1[0] * u),
        int(c0[1] * (1 - u) + c1[1] * u),
        int(c0[2] * (1 - u) + c1[2] * u),
    )


def gradient_stops_y(stops: list[tuple[float, tuple[int, int, int]]]) -> Image.Image:
    """Vertical gradient with multiple RGB stops; stops are (t_in_0_1, rgb)."""
    stops = sorted(stops, key=lambda s: s[0])
    im = Image.new("RGB", (W, H))
    px = im.load()
    h1 = H - 1
    for y in range(H):
        ty = y / h1 if h1 else 0.0
        if ty <= stops[0][0]:
            r, g, b = stops[0][1]
        elif ty >= stops[-1][0]:
            r, g, b = stops[-1][1]
        else:
            r, g, b = stops[0][1]
            for i in range(len(stops) - 1):
                t0, c0 = stops[i]
                t1, c1 = stops[i + 1]
                if t0 <= ty <= t1:
                    u = (ty - t0) / (t1 - t0) if t1 > t0 else 0.0
                    r, g, b = _lerp_rgb(c0, c1, u)
                    break
        for x in range(W):
            px[x, y] = (r, g, b)
    return im


def gradient_diagonal(c0: tuple[int, int, int], c1: tuple[int, int, int], c2: tuple[int, int, int]) -> Image.Image:
    """Diagonal blend: corner mix for extra pop."""
    im = Image.new("RGB", (W, H))
    px = im.load()
    denom = W + H - 2
    for y in range(H):
        for x in range(W):
            t = (x + y) / denom if denom else 0
            if t < 0.5:
                u = t * 2
                rgb = _lerp_rgb(c0, c1, u)
            else:
                u = (t - 0.5) * 2
                rgb = _lerp_rgb(c1, c2, u)
            px[x, y] = rgb
    return im


def draw_rainbow_stripes(d: ImageDraw.ImageDraw, y: int, height: int, margin: int = 40) -> None:
    n = len(RAINBOW)
    w = (W - 2 * margin) // n
    for i, hex_c in enumerate(RAINBOW):
        x0 = margin + i * w
        d.rectangle((x0, y, x0 + w + 2, y + height), fill=hex_c)


def draw_sparkles(d: ImageDraw.ImageDraw, coords_colors: list[tuple[int, int, str, int]]) -> None:
    for x, y, fill, r in coords_colors:
        d.ellipse((x - r, y - r, x + r, y + r), fill=fill, outline="#ffffff", width=1)


def draw_browser_chrome_rainbow(d: ImageDraw.ImageDraw, y0: int, title: str) -> None:
    d.rounded_rectangle((40, y0, W - 40, y0 + 38), radius=10, fill="#fff8fc", outline="#ff00aa", width=3)
    d.ellipse((52, y0 + 11, 70, y0 + 29), fill="#ff3366")
    d.ellipse((78, y0 + 11, 96, y0 + 29), fill="#ffcc00")
    d.ellipse((104, y0 + 11, 122, y0 + 29), fill="#00ff66")
    d.text((135, y0 + 9), title, fill="#220033", font=FONT_SM)
    draw_rainbow_stripes(d, y0 + 34, 5, 42)


def scene_title() -> Image.Image:
    im = gradient_stops_y(
        [
            (0.0, (255, 0, 180)),
            (0.25, (255, 140, 0)),
            (0.55, (0, 255, 220)),
            (0.8, (120, 0, 255)),
            (1.0, (255, 255, 0)),
        ]
    )
    d = ImageDraw.Draw(im)
    draw_sparkles(
        d,
        [
            (80, 70, "#ffffff", 14),
            (620, 90, "#ffff00", 12),
            (650, 320, "#00ffff", 16),
            (95, 340, "#ff00ff", 10),
            (400, 40, "#ffffff", 8),
        ],
    )
    d.rounded_rectangle((W // 2 - 230, 88, W // 2 + 230, 218), radius=20, fill="#00000055", outline="#ffffff", width=4)
    draw_rainbow_stripes(d, 205, 6, 200)
    d.text((W // 2, 130), "CopyURL", fill="#ffffff", font=FONT_LG, anchor="mm")
    d.text((W // 2, 175), "YouTube thumbnail → Gemini summary", fill="#fff566", font=FONT_MD, anchor="mm")
    d.text((W // 2, 285), "Windows · Alt+Z · AutoHotkey", fill="#b4ffff", font=FONT_SM, anchor="mm")
    return im


def scene_hover() -> Image.Image:
    im = gradient_diagonal((255, 60, 0), (255, 0, 200), (0, 100, 255))
    d = ImageDraw.Draw(im)
    draw_sparkles(
        d,
        [
            (55, 200, "#ffff00", 11),
            (680, 180, "#00ffcc", 13),
            (200, 55, "#ff66ff", 9),
        ],
    )
    draw_browser_chrome_rainbow(d, 28, "youtube.com  —  YouTube")
    y = 92
    cards = [
        (60, "#ff1744", "#ff8a80", "#ffd600"),
        (250, "#e040fb", "#ea80fc", "#ffff00"),
        (440, "#00e676", "#69f0ae", "#ff4081"),
    ]
    for x, fill, glow, stripe in cards:
        d.rounded_rectangle((x - 3, y - 3, x + 173, y + 103), radius=12, outline=glow, width=4)
        d.rounded_rectangle((x, y, x + 170, y + 100), radius=10, fill=fill, outline=stripe, width=3)
        d.rectangle((x + 8, y + 8, x + 162, y + 52), fill="#00000044")
        d.rectangle((x + 8, y + 58, x + 162, y + 92), fill=stripe)
    d.rounded_rectangle((245, y - 6, 425, y + 106), radius=14, outline="#ffff00", width=5)
    d.polygon([(360, y + 108), (380, y + 132), (340, y + 132)], fill="#ffea00", outline="#ff6d00", width=3)
    d.text((W // 2, 332), "1  Hover the video thumbnail", fill="#ffffff", font=FONT_MD, anchor="mm")
    d.rectangle((W // 2 - 200, 348, W // 2 + 200, 356), fill="#00e5ff")
    return im


def scene_hotkey() -> Image.Image:
    im = gradient_stops_y(
        [
            (0.0, (0, 80, 255)),
            (0.35, (180, 0, 255)),
            (0.7, (255, 0, 120)),
            (1.0, (255, 200, 0)),
        ]
    )
    d = ImageDraw.Draw(im)
    draw_sparkles(
        d,
        [
            (100, 120, "#00ffff", 15),
            (600, 100, "#ff00ff", 12),
            (500, 300, "#ffff00", 14),
        ],
    )
    draw_browser_chrome_rainbow(d, 28, "youtube.com  —  YouTube")
    d.rounded_rectangle((240, 82, 430, 192), radius=12, fill="#ff4081", outline="#ffea00", width=4)
    d.text((W // 2, 232), "2  Press", fill="#fff59d", font=FONT_MD, anchor="mm")
    d.rounded_rectangle((W // 2 - 120, 248, W // 2 + 120, 318), radius=16, fill="#ffea00", outline="#ff3d00", width=4)
    d.text((W // 2, 283), "Alt + Z", fill="#d50000", font=FONT_LG, anchor="mm")
    d.text((W // 2, 348), "Brave + extension → Gemini app", fill="#b3e5fc", font=FONT_SM, anchor="mm")
    draw_rainbow_stripes(d, 375, 8, 60)
    return im


def scene_gemini() -> Image.Image:
    im = gradient_stops_y(
        [
            (0.0, (0, 200, 180)),
            (0.4, (0, 150, 255)),
            (0.75, (100, 50, 255)),
            (1.0, (255, 50, 150)),
        ]
    )
    d = ImageDraw.Draw(im)
    draw_sparkles(
        d,
        [
            (70, 240, "#ffff00", 11),
            (640, 260, "#ff4081", 10),
            (400, 70, "#76ff03", 12),
        ],
    )
    draw_browser_chrome_rainbow(d, 28, "Gemini  —  Google Gemini")
    d.rounded_rectangle((56, 86, W - 56, 224), radius=14, fill="#1a237e", outline="#00e5ff", width=3)
    d.text((80, 108), "Summarize this YouTube video:", fill="#ffea00", font=FONT_SM)
    d.text((80, 142), "https://www.youtube.com/...  (your video link)", fill="#69f0ae", font=FONT_SM)
    d.rounded_rectangle((56, 246, W - 56, 326), radius=14, fill="#4a148c", outline="#ea80fc", width=3)
    d.text((80, 270), "3  Gemini uses the link as video context", fill="#e1bee7", font=FONT_SM)
    draw_rainbow_stripes(d, 336, 5, 80)
    return im


def scene_summary() -> Image.Image:
    im = gradient_diagonal((0, 255, 100), (255, 235, 59), (255, 64, 129))
    d = ImageDraw.Draw(im)
    draw_sparkles(
        d,
        [
            (120, 100, "#ffffff", 10),
            (580, 150, "#00bcd4", 14),
            (300, 360, "#ffeb3b", 11),
        ],
    )
    draw_browser_chrome_rainbow(d, 28, "Gemini  —  Google Gemini")
    d.rounded_rectangle((56, 86, W - 56, 304), radius=14, fill="#004d40", outline="#b9f6ca", width=4)
    d.text((80, 112), "Summary", fill="#ffeb3b", font=FONT_MD)
    d.text(
        (80, 158),
        "• Main idea from the video\n• Key points\n• Follow up in the same chat",
        fill="#a7ffeb",
        font=FONT_SM,
    )
    d.text((W // 2, 360), "4  Read the summary in Gemini", fill="#ffffff", font=FONT_MD, anchor="mm")
    draw_rainbow_stripes(d, 388, 10, 30)
    return im


def main() -> None:
    global FONT_LG, FONT_MD, FONT_SM
    OUT.parent.mkdir(parents=True, exist_ok=True)
    FONT_LG = try_font(32)
    FONT_MD = try_font(22)
    FONT_SM = try_font(18)

    scenes = [
        scene_title(),
        scene_hover(),
        scene_hotkey(),
        scene_gemini(),
        scene_summary(),
    ]

    frames: list[Image.Image] = []
    for im in scenes:
        for _ in range(HOLD):
            frames.append(im.copy())

    for _ in range(HOLD // 2):
        frames.append(scenes[0].copy())

    imageio.mimsave(
        OUT,
        [f.convert("P", palette=Image.ADAPTIVE, colors=256) for f in frames],
        fps=FPS,
        loop=0,
    )
    print(f"Wrote {OUT} ({len(frames)} frames @ {FPS} fps, ~{len(frames)/FPS:.1f}s loop)")


if __name__ == "__main__":
    main()
