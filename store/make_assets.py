"""Builds the Play Store images and the app logo files from store/logo_source.png and docs/screenshots.

Run from the repo root: python store/make_assets.py (needs Pillow). Then `dart run flutter_launcher_icons` and
`dart run flutter_native_splash:create` if the logo changed.
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

NAVY = (5, 55, 98)
YELLOW = (253, 176, 22)
LIGHT = (243, 246, 250)
FONT = 'C:/Windows/Fonts/segoeuib.ttf'  # ponytail: Windows-only font path, pass another TTF on other systems
OUT = Path('store/metadata/android')
SHOTS = Path('docs/screenshots')

# Order = order on the listing. Play allows up to 8 phone screenshots.
CAPTIONS = {
    'stop': ('Ogni arrivo, e quanto è affidabile', 'Every arrival, and how sure it is'),
    'vehicle': ('Segui il tuo bus sulla mappa', 'Follow your bus on the map'),
    'follow': ('Un avviso prima che passi', 'A heads-up before it arrives'),
    'nearby': ('Le fermate intorno a te', 'The stops around you'),
    'line-list': ('Tutte le fermate di una linea', 'Every stop of a line'),
    'line': ('Il percorso, dove sono i bus', 'The route and where buses are'),
    'alerts': ('Deviazioni e avvisi', 'Detours and service alerts'),
    'nearby-dark': ('Anche in tema scuro', 'Dark theme too'),
}
TAGLINE = ('Bus e tram di Roma, in tempo reale', 'Rome buses and trams, live')
LOCALES = ('it-IT', 'en-US')

logo = Image.open('store/logo_source.png').convert('RGBA')


def fit(img, w, h):
    img = img.copy()
    img.thumbnail((w, h), Image.LANCZOS)
    return img


def centered(canvas_size, img, bg=(0, 0, 0, 0)):
    canvas = Image.new('RGBA', canvas_size, bg)
    canvas.alpha_composite(img, ((canvas_size[0] - img.width) // 2, (canvas_size[1] - img.height) // 2))
    return canvas


def fit_font(draw, text, size, max_w):
    while draw.textlength(text, font=(font := ImageFont.truetype(FONT, size))) > max_w:
        size -= 2
    return font


def text_center(draw, cx, y, text, size, fill, max_w=960):
    font = fit_font(draw, text, size, max_w)
    draw.text((cx - draw.textlength(text, font=font) / 2, y), text, font=font, fill=fill)


# App logo files. logo.png: tight, used in the app UI. launcher_foreground.png: inside the 66/108 safe zone of
# adaptive icons and the Android 12 splash circle.
logo.save('assets/images/logo.png')
centered((1024, 1024), fit(logo, 500, 500)).save('assets/images/launcher_foreground.png')

for i, locale in enumerate(LOCALES):
    images = OUT / locale / 'images'
    (images / 'phoneScreenshots').mkdir(parents=True, exist_ok=True)

    # Play icon: 512x512 32-bit PNG. Full square, Play applies the rounded mask.
    centered((512, 512), fit(logo, 400, 400), (255, 255, 255, 255)).save(images / 'icon.png')

    # Feature graphic: 1024x500, no alpha.
    fg = Image.new('RGBA', (1024, 500), LIGHT + (255,))
    mark = fit(logo, 380, 280)
    fg.alpha_composite(mark, (70, (500 - mark.height) // 2))
    d = ImageDraw.Draw(fg)
    d.text((500, 150), 'Veribus', font=ImageFont.truetype(FONT, 110), fill=NAVY)
    d.rectangle((504, 300, 604, 308), fill=YELLOW)
    d.text((500, 330), TAGLINE[i], font=fit_font(d, TAGLINE[i], 34, 470), fill=NAVY)
    fg.convert('RGB').save(images / 'featureGraphic.png')

    # Phone screenshots: 1080x1920 (9:16), no alpha. Raw captures are 824x1830, over Play's 2:1 limit.
    for n, (name, caption) in enumerate(CAPTIONS.items(), 1):
        shot = Image.open(SHOTS / f'{name}.jpg').convert('RGBA')
        shot = shot.resize((round(shot.width * 1540 / shot.height), 1540), Image.LANCZOS)
        mask = Image.new('L', shot.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, *shot.size), 36, fill=255)
        canvas = Image.new('RGBA', (1080, 1920), NAVY + (255,))
        d = ImageDraw.Draw(canvas)
        text_center(d, 540, 120, caption[i], 62, (255, 255, 255))
        d.rectangle((490, 236, 590, 244), fill=YELLOW)
        canvas.paste(shot, ((1080 - shot.width) // 2, 310), mask)
        canvas.convert('RGB').save(images / 'phoneScreenshots' / f'{n}_{name}.png')

print('done')
