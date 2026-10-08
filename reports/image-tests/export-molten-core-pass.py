from pathlib import Path
import json
from PIL import Image, ImageOps, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[2]
manifest = json.loads((Path(__file__).parent / 'molten-core-pass-manifest.json').read_text())
dest = root / 'Media/final-images/molten-core'
dest.mkdir(parents=True, exist_ok=True)
sheet = Image.new('RGB', (1220, 3 * 435 + 50), '#171717')
draw = ImageDraw.Draw(sheet)
font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 23)
draw.text((20, 12), 'Original options                              Monochrome banner pass', font=font, fill='white')
for i, row in enumerate(manifest['images']):
    original = Image.open(row['path']).convert('RGB')
    generated = Image.open(row['generated']).convert('RGB')
    assert generated.width * 2 == generated.height * 3, (row['id'], generated.size)
    final = generated.resize((1200, 800), Image.Resampling.LANCZOS)
    final.save(dest / (row['id'] + '.jpg'), quality=90, optimize=True)
    y = 55 + i * 435
    draw.text((20, y), row['id'], font=font, fill='#e9cb72')
    for x, img in ((20, original), (620, final)):
        tile = ImageOps.contain(img, (580, 387), Image.Resampling.LANCZOS)
        sheet.paste(tile, (x + (580-tile.width)//2, y+32+(387-tile.height)//2))
sheet.save(Path(__file__).parent / 'molten-core-pass-before-after.jpg', quality=90, optimize=True)
for row in manifest['images']:
    file = dest / (row['id']+'.jpg')
    image = Image.open(file)
    assert image.size == (1200,800)
    r,g,b = image.split()
    from PIL import ImageChops, ImageStat
    # Imagegen may leave a slight near-neutral tint; check visual monochrome.
    for channel in (g,b):
        diff = ImageChops.difference(r, channel)
        assert ImageStat.Stat(diff).mean[0] < 3
        assert diff.getextrema()[1] <= 20
    print(file.name, image.size, file.stat().st_size)
