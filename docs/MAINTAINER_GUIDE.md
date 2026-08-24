# Scripture Scroller maintainer guide

This document preserves the implementation decisions and operating procedures behind Scripture Scroller. The root [README](../README.md) remains the user-facing installation and configuration guide.

## Project record

| Item | Value |
|---|---|
| Plugin ID | `networkchuck.scripture-scroller` |
| Plugin kind | Omarchy 4 `bar-widget` |
| Repository | <https://github.com/theNetworkChuck/omarchy-scripture-scroller> |
| First release | `v1.0.0`, 2026-08-23 |
| Marketplace submission | <https://github.com/HANCORE-linux/omarchy-plugin-marketplace/issues/1956> |
| Code license | MIT |
| Scripture translation | Berean Standard Bible (BSB), public domain |

## Product decisions

The original request called for encouraging ESV passages. The ESV license and API terms make bundling a keyless, redistributable offline passage collection inappropriate for this plugin. The BSB was selected instead because it is a modern English translation that its publisher placed in the public domain. This keeps installation private, instant, and reliable: the widget needs no account, API token, network request, runtime service, or cache.

The text shown by the widget is identified as BSB. Do not label alternate wording, paraphrases, or generated devotional text as BSB.

The plugin deliberately does not:

- download Scripture while running;
- collect analytics, credentials, or personal data;
- create background services or files outside Omarchy's normal plugin settings;
- overwrite the user's Hyprland, Quickshell, or shell configuration;
- require an install or uninstall hook.

## Repository map

| Path | Responsibility |
|---|---|
| `manifest.json` | Plugin identity, entry point, defaults, and settings schema |
| `Widget.qml` | Bar layout, timer, marquee, navigation, tooltip, and browser action |
| `Passages.js` | The 100 exact BSB references and passage strings |
| `tests/validate_passages.py` | Structural checks and optional exact source-text comparison |
| `assets/scripture-scroller.png` | User-facing and marketplace screenshot |
| `THIRD_PARTY_NOTICES.md` | BSB provenance and public-domain notice |
| `README.md` | Installation, controls, settings, removal, and basic development |
| `CHANGELOG.md` | Version history |

There are no build steps or runtime dependencies beyond the Omarchy 4 shell environment. QML imports `QtQuick`, `Quickshell`, and the Omarchy `Commons` and `Ui` modules already present on the target system.

## Runtime design

`Widget.qml` instantiates one `BarWidget` with module name `networkchuck.scripture-scroller`. On completion it creates a Fisher-Yates shuffle of indexes into `Passages.js`, selects the first passage, starts the marquee, and arms the rotation timer.

The important state is intentionally small:

- `order` holds the shuffled passage indexes for the current cycle;
- `orderIndex` points at the displayed entry and enables wheel-up history within that cycle;
- `currentPassage` holds the active reference and text;
- `hovered` combines with `pauseOnHover` to pause both animation and rotation.

When the cycle is exhausted, a new shuffle is generated. If its first index matches the previous cycle's last index, the first two indexes are exchanged. The result is one appearance per passage per cycle with no immediate repeat at the boundary. The shuffle is session state; it is not persisted across shell restarts.

The marquee moves from the right edge of its clipped area to the left of the full text. Its duration is based on distance and the configured minimum speed, but is capped at 90 percent of the rotation interval so a long passage can traverse the widget before the next one appears. Hovering restarts the marquee from the right when motion resumes.

On a vertical bar the widget uses the normal bar size and shows a compact Bible glyph. The complete passage remains available in the tooltip.

### Interactions

| Input | Result |
|---|---|
| Left click | Opens the current BSB chapter through `omarchy-launch-browser` |
| Right click | Advances and restarts the 30-second timer |
| Wheel down | Advances and restarts the timer |
| Wheel up | Returns within the current shuffle when history exists |
| Hover | Shows the complete passage and controls; pauses by default |

The browser URL is derived from the book and chapter in the reference and points to Bible Hub's BSB chapter page. `Psalm` is mapped to the site's `psalms` path. A malformed reference falls back to <https://berean.bible/>.

## Manifest and settings contract

`manifest.json` uses schema version 1, allows only one widget instance, and defaults to the center bar section. Keep the manifest defaults, schema defaults, QML fallback values, README table, and tests conceptually aligned whenever a setting changes.

| Key | Type | Default | Accepted range |
|---|---|---:|---:|
| `rotationIntervalSec` | integer | 30 | 10–300 seconds |
| `maxWidth` | integer | 420 | 200–800 pixels |
| `scrollSpeed` | integer | 45 | 20–120 pixels/second |
| `pauseOnHover` | boolean | `true` | boolean |

QML clamps numeric settings even if `shell.json` is edited by hand. Invalid numeric values fall back to the defaults.

## Scripture provenance and maintenance

The canonical source used for v1.0.0 is:

- URL: <https://bereanbible.com/bsb.txt>
- retrieval date: 2026-08-23
- SHA-256: `2ac3af1de52d4e68261cba91d85c320b7eadc6560e830d99e591767b8ff5ca96`

The 100 strings in `Passages.js` were extracted without paraphrasing. After removing each dataset line's line ending and outer whitespace, the validation script treats internal whitespace, punctuation, capitalization, and Unicode quotation marks as meaningful, so any difference from the official text fails comparison.

To audit or update the collection:

1. Download `bsb.txt` directly from the canonical URL to a temporary path.
2. Record the retrieval date and `sha256sum` in the README, this guide, and the source comment in `Passages.js` if the source changed.
3. Select unique verse references. Keep the collection at 100 unless the runtime and structural assertion are intentionally changed together.
4. Copy the exact tab-separated verse text from the source into `Passages.js`; do not normalize punctuation or rewrite it.
5. Run both validation commands in the next section.
6. Review the selection for an encouraging tone. This is a human editorial check, not something the structural test can prove.

If the upstream licensing status changes, stop distributing new Scripture data until the legal and attribution implications are reviewed. Preserve `THIRD_PARTY_NOTICES.md` in every distribution.

## Validation and test matrix

Run the local checks from the repository root:

```bash
omarchy plugin validate .
python3 tests/validate_passages.py
python3 tests/validate_passages.py /tmp/bsb-scripture-scroller.txt
git diff --check
```

The first test validates the Omarchy plugin structure and manifest. The second verifies that exactly 100 entries exist, references are unique, text is nonempty, and entries contain only `reference` and `text`. The third additionally compares every entry with an official BSB download. The final command finds whitespace errors in the pending Git diff.

For any QML behavior change, also perform a live shell check:

1. Install or update the development copy.
2. Confirm the widget renders in a horizontal bar without clipping adjacent modules.
3. Leave it visible for more than one configured interval and confirm rotation.
4. Test hover pause and tooltip, right click, both wheel directions, and left-click browser launch.
5. Temporarily use a vertical bar or inspect in a vertical test configuration to verify compact mode.
6. Inspect recent shell logs for QML errors.

For v1.0.0, the project passed manifest validation, the 100-entry structural test, exact comparison against the canonical dataset, live rendering, automatic rotation, and a clean shell-log check.

## Local installation lifecycle

Install from GitHub and position the widget:

```bash
omarchy plugin add https://github.com/theNetworkChuck/omarchy-scripture-scroller.git --enable
omarchy bar move networkchuck.scripture-scroller --before omarchy.clock
```

Pull a published update:

```bash
omarchy plugin update networkchuck.scripture-scroller --yes
```

Remove the plugin:

```bash
omarchy plugin remove networkchuck.scripture-scroller
```

The installed checkout is normally `~/.config/omarchy/plugins/networkchuck.scripture-scroller`; user settings and placement are stored by Omarchy in `~/.config/omarchy/shell.json`. Removal requires no plugin-specific cleanup because the plugin creates no services, caches, credentials, or data files.

During development, use Omarchy's supported plugin development workflow instead of copying individual files into the installed checkout. After edits, validate the repository, refresh or update the plugin, and inspect the live shell.

## Versioning and release checklist

Use semantic versions in `manifest.json`. A user-visible feature or compatible setting addition is normally a minor release; a compatible bug fix is a patch release; an incompatible manifest, setting, or behavior contract requires a major release. Documentation-only commits do not require a plugin version bump.

For a release:

1. Complete the full validation and live test matrix.
2. Update `CHANGELOG.md`, replace `Unreleased` entries with the new version and date, and set the same version in `manifest.json`.
3. Check `git status`, review the complete diff, commit, and push `main`.
4. Create an annotated Git tag named `v<version>` at the tested commit and push it.
5. Create the matching GitHub release with concise user-facing notes.
6. Update a clean installed copy and rerun a live smoke test.
7. If the plugin is not yet listed, edit the existing marketplace submission to trigger fresh exact-commit validation. If it is already listed, use the marketplace's **Plugin verification** form for the new full 40-character commit SHA.
8. Do not request maintainer approval until the marketplace validation and automated security baseline both describe the exact commit intended for publication.

Marketplace validation is commit-bound. Any repository commit after a scan—even documentation-only—makes the old report stale for initial listing approval. The current submission should be edited and revalidated rather than duplicated.

## Security and privacy boundary

The plugin code runs with the same user privileges as the Omarchy shell; it is not sandboxed. Its only external action is a user-initiated browser launch. Scripture is read from the bundled JavaScript file, and the timer, shuffle, and animation remain in memory.

Review changes carefully if they introduce any network access, shell execution, file writes, credentials, persistent state, new QML imports, or external dependencies. Such changes alter the documented privacy and security boundary and require updated user documentation plus a new marketplace security scan.

## Troubleshooting

### The widget is installed but not visible

Confirm it is enabled and has a bar placement. Re-run the `omarchy bar move` command above, then inspect `~/.config/omarchy/shell.json` rather than editing generated shell internals.

### The passage does not move

Move the pointer off the widget if `pauseOnHover` is enabled. Very short text may have less obvious motion, while a manually configured interval or speed is clamped to its documented range.

### Wheel up does nothing

There is no earlier entry before the first passage in a newly generated shuffle. History is intentionally limited to the active cycle and is reset on a shell restart.

### A browser page does not match the verse

The click target is the BSB chapter, not a verse anchor. Check the reference parser and Bible Hub book slug if adding a book name whose URL does not follow the current lowercase-and-underscore rule.

### Source validation reports a mismatch

Confirm the download's SHA-256, UTF-8 decoding, reference, punctuation, quotation marks, and whitespace. Treat the official tab-separated text as canonical; do not loosen the comparison to make an edited string pass.

### Marketplace reports an older commit

Push all intended changes, edit the existing submission issue to rerun validation, and wait for both bot comments to name the current full commit before requesting review.

## Current publication state

As of 2026-08-23, v1.0.0 is publicly released and marketplace submission [#1956](https://github.com/HANCORE-linux/omarchy-plugin-marketplace/issues/1956) is awaiting a human listing decision after automated validation. The issue is the source of truth for its current state.
