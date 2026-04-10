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
# Slower pacing: lower FPS + longer hold per scene (~3.5s each at 5 fps)
FPS = 5
HOLD = int(FPS * 3.5)


def try_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for name in ("segoeui.ttf", "arial.ttf", "calibri.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def gradient_rgb(top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    """Vertical gradient background."""
    im = Image.new("RGB", (W, H))
    px = im.load()
    h1 = H - 1
    for y in range(H):
        t = y / h1 if h1 else 0.0
        r = int(top[0] * (1 - t) + bottom[0] * t)
        g = int(top[1] * (1 - t) + bottom[1] * t)
        b = int(top[2] * (1 - t) + bottom[2] * t)
        for x in range(W):
            px[x, y] = (r, g, b)
    return im


def draw_browser_chrome(
    d: ImageDraw.ImageDraw, y0: int, title: str, accent: str, bar_fill: str
) -> None:
    d.rounded_rectangle((40, y0, W - 40, y0 + 36), radius=8, fill=bar_fill, outline=accent, width=2)
    d.rectangle((40, y0 + 32, W - 40, y0 + 36), fill=accent)
    d.ellipse((52, y0 + 10, 68, y0 + 26), fill="#ff5f57")
    d.ellipse((76, y0 + 10, 92, y0 + 26), fill="#febc2e")
    d.ellipse((100, y0 + 10, 116, y0 + 26), fill="#28c840")
    d.text((130, y0 + 8), title, fill="#1a1a2e", font=FONT_SM)


def scene_title() -> Image.Image:
    im = gradient_rgb((88, 28, 135), (30, 58, 138))  # purple → deep blue
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((W // 2 - 220, 95, W // 2 + 220, 210), radius=16, fill="#ffffff22", outline="#ffd700", width=3)
    d.text((W // 2, 125), "CopyURL", fill="#ffe566", font=FONT_LG, anchor="mm")
    d.text((W // 2, 175), "YouTube thumbnail → Gemini summary", fill="#e0e7ff", font=FONT_MD, anchor="mm")
    d.text((W // 2, 285), "Windows · Alt+Z · AutoHotkey", fill="#c4b5fd", font=FONT_SM, anchor="mm")
    return im


def scene_hover() -> Image.Image:
    im = gradient_rgb((180, 40, 40), (45, 20, 60))  # red-wine → plum
    d = ImageDraw.Draw(im)
    draw_browser_chrome(d, 28, "youtube.com  —  YouTube", "#ff1744", "#fff5f5")
    y = 90
    colors = (("#ff6b6b", "#c92a2a"), ("#a855f7", "#6d28d9"), ("#22d3ee", "#0891b2"))
    xs = (60, 250, 440)
    for (x, (fill, edge)) in zip(xs, colors, strict=True):
        d.rounded_rectangle((x, y, x + 170, y + 100), radius=10, fill=fill, outline=edge, width=2)
        d.rectangle((x + 10, y + 10, x + 160, y + 55), fill="#00000033")
    d.rounded_rectangle((248, y - 4, 422, y + 104), radius=12, outline="#ffeb3b", width=4)
    d.polygon([(360, y + 108), (375, y + 128), (345, y + 128)], fill="#ffeb3b", outline="#ff9800", width=2)
    d.text((W // 2, 330), "1  Hover the video thumbnail", fill="#fff9c4", font=FONT_MD, anchor="mm")
    return im


def scene_hotkey() -> Image.Image:
    im = gradient_rgb((37, 99, 235), (109, 40, 217))  # blue → violet
    d = ImageDraw.Draw(im)
    draw_browser_chrome(d, 28, "youtube.com  —  YouTube", "#60a5fa", "#eff6ff")
    d.rounded_rectangle((248, 86, 422, 186), radius=10, fill="#f472b6", outline="#fbcfe8", width=3)
    d.text((W // 2, 235), "2  Press", fill="#e0e7ff", font=FONT_MD, anchor="mm")
    d.rounded_rectangle((W // 2 - 110, 252, W // 2 + 110, 312), radius=14, fill="#fbbf24", outline="#f59e0b", width=3)
    d.text((W // 2, 282), "Alt + Z", fill="#78350f", font=FONT_LG, anchor="mm")
    d.text((W // 2, 345), "Brave + extension → Gemini app", fill="#c7d2fe", font=FONT_SM, anchor="mm")
    return im


def scene_gemini() -> Image.Image:
    im = gradient_rgb((13, 148, 136), (30, 64, 175))  # teal → indigo
    d = ImageDraw.Draw(im)
    draw_browser_chrome(d, 28, "Gemini  —  Google Gemini", "#34d399", "#ecfdf5")
    d.rounded_rectangle((60, 90, W - 60, 220), radius=12, fill="#1e293b", outline="#38bdf8", width=2)
    d.text((80, 110), "Summarize this YouTube video:", fill="#fde68a", font=FONT_SM)
    d.text((80, 145), "https://www.youtube.com/...  (your video link)", fill="#7dd3fc", font=FONT_SM)
    d.rounded_rectangle((60, 250, W - 60, 320), radius=12, fill="#312e81", outline="#a78bfa", width=2)
    d.text((80, 268), "3  Gemini uses the link as video context", fill="#ddd6fe", font=FONT_SM)
    return im


def scene_summary() -> Image.Image:
    im = gradient_rgb((22, 101, 52), (6, 78, 59))  # emerald tones
    d = ImageDraw.Draw(im)
    draw_browser_chrome(d, 28, "Gemini  —  Google Gemini", "#4ade80", "#f0fdf4")
    d.rounded_rectangle((60, 90, W - 60, 300), radius=12, fill="#14532d", outline="#86efac", width=2)
    d.text((80, 115), "Summary", fill="#fef08a", font=FONT_MD)
    d.text(
        (80, 160),
        "• Main idea from the video\n• Key points\n• Follow up in the same chat",
        fill="#bbf7d0",
        font=FONT_SM,
    )
    d.text((W // 2, 360), "4  Read the summary in Gemini", fill="#ecfccb", font=FONT_MD, anchor="mm")
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
        [f.convert("P", palette=Image.ADAPTIVE, colors=128) for f in frames],
        fps=FPS,
        loop=0,
    )
    print(f"Wrote {OUT} ({len(frames)} frames @ {FPS} fps, ~{len(frames)/FPS:.1f}s loop)")


if __name__ == "__main__":
    main()
