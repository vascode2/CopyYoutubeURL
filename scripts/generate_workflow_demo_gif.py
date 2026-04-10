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
FPS = 8
HOLD = int(FPS * 1.35)  # ~1.35s per scene


def try_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for name in ("segoeui.ttf", "arial.ttf", "calibri.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def solid(bg: str) -> Image.Image:
    return Image.new("RGB", (W, H), bg)


def draw_browser_chrome(d: ImageDraw.ImageDraw, y0: int, title: str, color: str) -> None:
    d.rounded_rectangle((40, y0, W - 40, y0 + 36), radius=6, fill="#2d2d3a", outline="#444")
    d.ellipse((52, y0 + 10, 68, y0 + 26), fill="#ff5f57")
    d.ellipse((76, y0 + 10, 92, y0 + 26), fill="#febc2e")
    d.ellipse((100, y0 + 10, 116, y0 + 26), fill="#28c840")
    d.text((130, y0 + 8), title, fill="#ddd", font=FONT_SM)


def scene_title() -> Image.Image:
    im = solid("#12121c")
    d = ImageDraw.Draw(im)
    d.text((W // 2, 120), "CopyURL", fill="#fff", font=FONT_LG, anchor="mm")
    d.text((W // 2, 190), "YouTube thumbnail → Gemini summary", fill="#aaa", font=FONT_MD, anchor="mm")
    d.text((W // 2, 280), "Windows · Alt+Z · AutoHotkey", fill="#666", font=FONT_SM, anchor="mm")
    return im


def scene_hover() -> Image.Image:
    im = solid("#12121c")
    d = ImageDraw.Draw(im)
    draw_browser_chrome(d, 28, "youtube.com  —  YouTube", "#f00")
    # Video grid mock
    y = 90
    for i, x in enumerate((60, 250, 440)):
        d.rounded_rectangle((x, y, x + 170, y + 100), radius=8, fill="#2a2a35", outline="#333")
        d.rectangle((x + 8, y + 8, x + 162, y + 58), fill="#1e3a5f")
    # Highlight middle thumb
    d.rounded_rectangle((248, y - 4, 422, y + 104), radius=10, outline="#ff4444", width=3)
    d.polygon([(360, y + 110), (370, y + 125), (350, y + 125)], fill="#fff")
    d.text((W // 2, 330), "1  Hover the video thumbnail", fill="#e0e0e0", font=FONT_MD, anchor="mm")
    return im


def scene_hotkey() -> Image.Image:
    im = solid("#12121c")
    d = ImageDraw.Draw(im)
    draw_browser_chrome(d, 28, "youtube.com  —  YouTube", "#f00")
    d.rounded_rectangle((248, 86, 422, 186), radius=8, fill="#2a2a35", outline="#ff4444", width=2)
    d.text((W // 2, 240), "2  Press  Alt + Z", fill="#fff", font=FONT_LG, anchor="mm")
    d.rounded_rectangle((W // 2 - 95, 200, W // 2 + 95, 248), radius=8, fill="#3d3d52", outline="#888")
    d.text((W // 2, 224), "Alt + Z", fill="#ffcc66", font=FONT_LG, anchor="mm")
    d.text((W // 2, 320), "Brave + extension copy URL → Gemini app", fill="#888", font=FONT_SM, anchor="mm")
    return im


def scene_gemini() -> Image.Image:
    im = solid("#12121c")
    d = ImageDraw.Draw(im)
    draw_browser_chrome(d, 28, "Gemini  —  Google Gemini", "#4285f4")
    d.rounded_rectangle((60, 90, W - 60, 220), radius=10, fill="#1e1e2e", outline="#333")
    d.text((80, 110), "Summarize this YouTube video:", fill="#ccc", font=FONT_SM)
    d.text((80, 145), "https://www.youtube.com/...  (your video link)", fill="#8ab4f8", font=FONT_SM)
    d.rounded_rectangle((60, 250, W - 60, 320), radius=10, fill="#252536", outline="#333")
    d.text((80, 268), "3  Prompt sent — Gemini uses the link as video context", fill="#aaa", font=FONT_SM)
    return im


def scene_summary() -> Image.Image:
    im = solid("#12121c")
    d = ImageDraw.Draw(im)
    draw_browser_chrome(d, 28, "Gemini  —  Google Gemini", "#4285f4")
    d.rounded_rectangle((60, 90, W - 60, 300), radius=10, fill="#1e1e2e", outline="#333")
    d.text((80, 115), "Summary", fill="#fff", font=FONT_MD)
    d.text(
        (80, 160),
        "• Main idea from the video\n• Key points\n• Follow up in the same chat",
        fill="#bbb",
        font=FONT_SM,
    )
    d.text((W // 2, 360), "4  Read the summary in Gemini", fill="#e0e0e0", font=FONT_MD, anchor="mm")
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

    # loop back to title briefly
    for _ in range(HOLD // 2):
        frames.append(scenes[0].copy())

    imageio.mimsave(
        OUT,
        [f.convert("P", palette=Image.ADAPTIVE, colors=64) for f in frames],
        fps=FPS,
        loop=0,
    )
    print(f"Wrote {OUT} ({len(frames)} frames @ {FPS} fps)")


if __name__ == "__main__":
    main()
