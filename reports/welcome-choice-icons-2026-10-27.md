# Welcome choice icons

The approved v2 gold icons are now in `Media/icons`:

| Welcome choice | Runtime texture | Untouched generated original |
|---|---|---|
| Browse goals | `Media/icons/browse-goals.tga` | `Media/artwork/ui-icons/welcome-goal-book-v2-generated-original.png` |
| Help me get started | `Media/icons/help-get-started.tga` | `Media/artwork/ui-icons/welcome-guided-compass-v2-generated-original.png` |

Both are 64 x 64, 32-bit RGBA and have corresponding `-source.png` files in `Media/icons`. Converted with `tools/icon.py`, then palette matched with `tools/gold.py` (book +6 degrees hue, compass +8 degrees; saturation x0.97 for both). They are available through `FGT.Icon("browse-goals")` and `FGT.Icon("help-get-started")`. The welcome screen has not been changed to use them. A full game restart is needed to review new textures in game.
