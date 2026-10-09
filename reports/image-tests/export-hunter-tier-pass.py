from pathlib import Path
import json
from PIL import Image

root = Path(__file__).resolve().parents[2]
targets = json.loads((Path(__file__).parent / 'hunter-tier-pass.json').read_text())['targets']
dest = root / 'Media/final-images/tier-sets/hunter'
dest.mkdir(parents=True, exist_ok=True)
for row in targets:
    generated = Image.open(row['generated']).convert('RGB')
    assert abs(generated.width/generated.height - 4/3) < 0.01, generated.size
    file = dest / (row['id'] + '.jpg')
    generated.resize((1200,900), Image.Resampling.LANCZOS).save(file, quality=90, optimize=True)
    assert Image.open(file).size == (1200,900)
    print(file.name, file.stat().st_size)
