from pathlib import Path
import json
from PIL import Image, ImageOps, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[2]
manifest = json.loads((Path(__file__).parent / 'additional-banner-pass.json').read_text())
dest = root / 'Media/final-images/additional-goals'
dest.mkdir(parents=True, exist_ok=True)
sheet = Image.new('RGB', (1220, len(manifest['targets']) * 435 + 50), '#171717')
draw = ImageDraw.Draw(sheet)
font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 23)
draw.text((20, 12), 'Original options                              Monochrome banner pass', font=font, fill='white')
labels = ['Lokdelar', 'Winterspring Frostsaber', 'Embrace of the Viper', 'Cenarion Circle', 'Skeleton Key / Scholomance']
for i, row in enumerate(manifest['targets']):
    original = Image.open(row['path']).convert('RGB')
    generated = Image.open(row['generated']).convert('RGB')
    assert generated.width * 2 == generated.height * 3, (row['id'], generated.size)
    final = generated.resize((1200, 800), Image.Resampling.LANCZOS)
    file = dest / (row['id'] + '.jpg')
    final.save(file, quality=90, optimize=True)
    assert Image.open(file).size == (1200, 800)
    print(file.name, file.stat().st_size)
    y = 55 + i * 435
    draw.text((20, y), labels[i], font=font, fill='#e9cb72')
    for x, img in ((20, original), (620, final)):
        tile = ImageOps.contain(img, (580, 387), Image.Resampling.LANCZOS)
        sheet.paste(tile, (x + (580 - tile.width)//2, y + 32 + (387 - tile.height)//2))
sheet.save(Path(__file__).parent / 'additional-banner-pass-before-after.jpg', quality=90, optimize=True)
