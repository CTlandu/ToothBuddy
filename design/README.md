# Design source assets

Plan U1 (`docs/plans/2026-05-28-002-feat-app-store-launch-plan.md`).

## App Icon

Three SVG sources for the iOS 18 three-state app icon:

- `app-icon.svg` — **Light** variant: white tooth on Duo.green BG, chunky ink outline, ink offset shadow
- `app-icon-dark.svg` — **Dark** variant: white tooth with Duo.green outline on ink-near-black BG
- `app-icon-tinted.svg` — **Tinted** variant: light-gray tooth on dark BG (iOS applies user's tint)

The compiled 1024×1024 PNGs live in `Assets.xcassets/AppIcon.appiconset/`. Xcode 14+ auto-derives all device-specific sizes from the single 1024×1024 source per appearance.

### Re-rendering

`qlmanage` (built into macOS Quick Look) is the simplest renderer:

```bash
qlmanage -t -s 1024 -o /tmp \
  design/app-icon.svg \
  design/app-icon-dark.svg \
  design/app-icon-tinted.svg

cp /tmp/app-icon.svg.png        Assets.xcassets/AppIcon.appiconset/icon-light-1024.png
cp /tmp/app-icon-dark.svg.png   Assets.xcassets/AppIcon.appiconset/icon-dark-1024.png
cp /tmp/app-icon-tinted.svg.png Assets.xcassets/AppIcon.appiconset/icon-tinted-1024.png
```

For cleaner SVG → PNG (e.g. fixing antialiasing artifacts at the stroke joins), install librsvg:

```bash
brew install librsvg
rsvg-convert -w 1024 -h 1024 design/app-icon.svg > \
  Assets.xcassets/AppIcon.appiconset/icon-light-1024.png
```

### Design system reference

Colors track `DuoTheme.swift`:

| Token | Hex | Use |
|-------|-----|-----|
| Duo.green | `#58CC02` | Light BG + Dark outline |
| Duo.ink | `#2B2535` | Light outline + offset shadow |
| Duo.cream / off-white | `#FFFFFF` | tooth body |
| Dark BG | `#1A1525` | Dark + Tinted background |

The tooth path is symmetric across `x = 512`, with the crown at `y = 200` and the root tips at `y = 836`. The offset shadow is `translate(32, 32)` (4pt at 1024 scale, matching `Duo.Layout.depthOffset = 4`).

Re-renders are intentionally hand-driven; there is no Makefile / build step. The PNGs are committed because they're what Xcode actually consumes.
