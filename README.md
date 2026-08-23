# Scripture Scroller for Omarchy

Scripture Scroller is an offline Omarchy 4 bar widget that gently cycles through 100 encouraging passages from the Berean Standard Bible (BSB).

No account, API key, network request, daemon, or install hook is required. The selected BSB passages are bundled with the plugin and the Bible text is in the public domain.

![Scripture Scroller showing Hebrews 10:23 in the Omarchy bar](assets/scripture-scroller.png)

## Install

```bash
omarchy plugin add https://github.com/theNetworkChuck/omarchy-scripture-scroller.git --enable
omarchy bar move networkchuck.scripture-scroller --before omarchy.clock
```

The widget defaults to the center section. Omarchy stores its settings and placement in `~/.config/omarchy/shell.json`.

## Controls

- Left-click opens the current BSB chapter in your default browser.
- Right-click advances to the next passage.
- Scroll up returns to the previous passage in the current shuffle; scroll down advances.
- Hover shows the complete passage and pauses the ticker by default.

The widget shuffles all 100 passages without repetition before beginning a new shuffle. It also prevents the last passage of one cycle from immediately becoming the first passage of the next.

## Settings

Use Omarchy's bar settings UI, or set values directly:

```bash
omarchy bar set networkchuck.scripture-scroller rotationIntervalSec 30
omarchy bar set networkchuck.scripture-scroller maxWidth 420
omarchy bar set networkchuck.scripture-scroller scrollSpeed 45
omarchy bar set networkchuck.scripture-scroller pauseOnHover true --json
```

Supported settings:

| Setting | Default | Range | Purpose |
|---|---:|---:|---|
| `rotationIntervalSec` | 30 | 10–300 | Seconds between passages |
| `maxWidth` | 420 | 200–800 | Horizontal ticker width in pixels |
| `scrollSpeed` | 45 | 20–120 | Minimum pixels per second |
| `pauseOnHover` | `true` | boolean | Pause movement and rotation on hover |

Long passages automatically accelerate enough to cross the ticker before the next rotation. Vertical bars show a compact Bible icon and expose the current passage in the tooltip.

## Scripture source

The passage text was extracted without paraphrasing from the official Berean Standard Bible plain-text dataset:

- Source: <https://bereanbible.com/bsb.txt>
- Retrieved: 2026-08-23
- SHA-256: `2ac3af1de52d4e68261cba91d85c320b7eadc6560e830d99e591767b8ff5ca96`

The BSB was dedicated to the public domain on April 30, 2023. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Development

```bash
omarchy plugin validate .
python3 tests/validate_passages.py /tmp/bsb-scripture-scroller.txt
```

The second command is optional and compares every bundled passage byte-for-byte with an official `bsb.txt` download.

## License

The plugin code is MIT licensed. The bundled BSB Scripture text is public domain.
