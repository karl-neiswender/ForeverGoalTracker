"""Technical export only: preserve generated 4:3 framing; originals unchanged."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[2]
manifest = json.loads((Path(__file__).parent / 'taller-banner-pass.json').read_text())
dest = root / 'Media/final-images/tall-1200x900'
dest.mkdir(parents=True, exist_ok=True)
font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 23)
for row in manifest['targets']:
    image = Image.open(row['generated']).convert('RGB')
    assert abs(image.width/image.height - 4/3) < 0.01, (row['id'], image.size)
    image.resize((1200,900), Image.Resampling.LANCZOS).save(
        dest / (row['id'] + '.jpg'), quality=90, optimize=True)
    assert Image.open(dest / (row['id']+'.jpg')).size == (1200,900)
    print(row['id'], (dest / (row['id']+'.jpg')).stat().st_size)
for page in range(2):
    sheet = Image.new('RGB', (1240, 1980), '#171717')
    draw = ImageDraw.Draw(sheet)
    draw.text((20, 10), '1200 x 900 masters - baked bottom gradient', font=font, fill='white')
    for i,row in enumerate(manifest['targets'][page*8:page*8+8]):
        x, y = 20+(i%2)*610, 55+(i//2)*480
        draw.text((x,y), row['id'], font=font, fill='#e9cb72')
        image = Image.open(dest / (row['id']+'.jpg'))
        sheet.paste(image.resize((590,443), Image.Resampling.LANCZOS), (x,y+30))
    sheet.save(Path(__file__).parent / f'taller-banner-review-{page+1}.jpg', quality=90, optimize=True)
