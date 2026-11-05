"""Generate Aphora launcher icon assets.

Run:  python tool/make_icon.py
Writes assets/icon/{icon.png, fg.png, bg.png, mono.png} (1024x1024), which
flutter_launcher_icons turns into Android adaptive + iOS icons.

Design: white speech bubble holding a voice waveform on clinical teal.
The bars rise and settle like a spoken word; the peak bar uses the app's
warm accent. Drawn at 4x and downsampled for clean anti-aliased edges.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parent.parent / "assets" / "icon"
OUT.mkdir(parents=True, exist_ok=True)

S = 4                      # supersample factor
N = 1024 * S               # working canvas
TEAL_TOP = (20, 132, 124)  # lighter teal, top-left
TEAL_BOT = (10, 82, 79)    # deep teal, bottom-right
INK = (15, 110, 106)       # AphColors.primary
ACCENT = (214, 112, 72)    # warm terracotta
WHITE = (255, 255, 255)
HEIGHTS = [120, 214, 318, 236, 140]
BAR_W, GAP, MID_Y = 62, 40, 476


def gradient_bg(n: int) -> Image.Image:
    """Diagonal teal gradient (built small, then scaled for speed)."""
    small = Image.new("RGB", (256, 256))
    px = small.load()
    for y in range(256):
        for x in range(256):
            t = (x + y) / 510
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(TEAL_TOP, TEAL_BOT))
    return small.resize((n, n), Image.BICUBIC)


def mapper(scale: float, cx: float, cy: float):
    def P(x, y):  # 1024-grid point -> canvas
        return (cx + (x - 512) * scale * S, cy + (y - 512) * scale * S)

    def R(v):
        return v * scale * S
    return P, R


def draw_bubble(d, scale, cx, cy, fill):
    """Bubble + tail drawn as one silhouette, then blurred and re-thresholded
    so the tail tip and its joins with the body come out smoothly rounded."""
    P, R = mapper(scale, cx, cy)
    img = d._image
    m = Image.new("L", img.size, 0)
    md = ImageDraw.Draw(m)
    md.rounded_rectangle([*P(196, 236), *P(828, 716)], radius=R(168), fill=255)
    md.polygon([P(228, 600), P(480, 712), P(236, 872)], fill=255)  # tail
    m = m.filter(ImageFilter.GaussianBlur(R(22)))
    m = m.point(lambda v: 255 if v >= 128 else 0)
    m = m.filter(ImageFilter.GaussianBlur(S * 0.6))  # keep AA after threshold
    layer = Image.new(img.mode, img.size, fill)
    img.paste(layer, (0, 0), m)


def draw_bars(d, scale, cx, cy, fill, peak=None):
    P, R = mapper(scale, cx, cy)
    total = len(HEIGHTS) * BAR_W + (len(HEIGHTS) - 1) * GAP
    left = 512 - total / 2
    for i, h in enumerate(HEIGHTS):
        bx = left + i * (BAR_W + GAP)
        d.rounded_rectangle([*P(bx, MID_Y - h / 2), *P(bx + BAR_W, MID_Y + h / 2)],
                            radius=R(BAR_W / 2),
                            fill=peak if (peak and i == 2) else fill)


def save(img: Image.Image, name: str):
    img.resize((1024, 1024), Image.LANCZOS).save(OUT / name)


c = N / 2

# 1) Full icon (iOS / legacy Android). iOS rounds the corners itself.
full = gradient_bg(N)
d = ImageDraw.Draw(full)
draw_bubble(d, 1.0, c, c, WHITE)
draw_bars(d, 1.0, c, c, INK, ACCENT)
save(full, "icon.png")

# 2) Adaptive background layer.
save(gradient_bg(N), "bg.png")

# 3) Adaptive foreground: mark scaled into the 66% safe zone, transparent bg.
FG_SCALE, FG_DY = 0.78, -10 * S
fg = Image.new("RGBA", (N, N), (0, 0, 0, 0))
d = ImageDraw.Draw(fg)
draw_bubble(d, FG_SCALE, c, c + FG_DY, WHITE)
draw_bars(d, FG_SCALE, c, c + FG_DY, INK + (255,), ACCENT + (255,))
save(fg, "fg.png")

# 4) Monochrome (Android 13 themed icons): bubble with the waveform cut out.
mono = Image.new("RGBA", (N, N), (0, 0, 0, 0))
d = ImageDraw.Draw(mono)
draw_bubble(d, FG_SCALE, c, c + FG_DY, (255, 255, 255, 255))
draw_bars(d, FG_SCALE, c, c + FG_DY, (0, 0, 0, 0))
save(mono, "mono.png")

print("wrote", sorted(p.name for p in OUT.iterdir()))
