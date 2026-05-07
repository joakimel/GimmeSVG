# CLAUDE.md

Kontekst for AI-assistenter (Claude Code o.l.) som jobber med dette prosjektet.

## Hva dette er

Gimme SVG – en native macOS-app som scraper SVG-bilder fra nettsider og
lar brukeren laste dem ned. Bygd i SwiftUI, kompilert med ren `swiftc`
fra CLI (intet Xcode-prosjekt).

**All kommunikasjon til brukeren og UI-tekst er på norsk (bokmål).**

## Tekniske rammer som ikke må endres uten å spørre

- **Single-file SwiftUI-app**: Hele app-kildekoden ligger i én fil –
  `Sources/main.swift`. Ikke splitt opp i moduler / `Package.swift` /
  Xcode-prosjekt uten å avklare.
- **Ingen tredjepartsavhengigheter**: Bare innebygde Apple-rammeverk
  (`Cocoa`, `SwiftUI`, `WebKit`). Ikke foreslå SwiftSoup, SnapKit,
  Alamofire e.l.
- **`NSApplication` + `AppDelegate`** (ikke `@main App`-makro). Sistnevnte
  er vanskelig fra ren `swiftc`.
- **Ad-hoc signering**: `codesign --force --deep --sign -`. Brukeren har
  ikke Apple Developer-konto.

## Bygg & test

```bash
./build.sh                      # bygger til ~/Desktop/Gimme SVG.app
open "$HOME/Desktop/Gimme SVG.app"
```

`build.sh` bruker bare `swiftc`, `sips`, `iconutil`, `codesign` – alt fra
Xcode CLI tools.

For å oppdatere ikonet: bytt `Resources/app-icon.png` og kjør `./build.sh`.

## Ting som IKKE fungerte – ikke prøv på nytt

| Tilnærming | Hvorfor det ble droppet |
|---|---|
| Python + tkinter med PyInstaller | Tcl/Tk pakkes ikke korrekt, vinduet blir tomt på arm64 |
| Python + tkinter via system-Python | URL-felt usynlig pga. `aqua`-tema-bugs |
| Lokal HTTP-server + nettleser-UI | Funket, men brukeren vil ha *native* app |
| `NSImage` for ikon-bygging | Sliter med kompleks `<defs>`+CSS-struktur i SVG |

Detaljer i [DEVELOPMENT.md](DEVELOPMENT.md).

## Kjente fallgruver i Swift-koden

- **Brede SVGer overflower grid-celler** hvis `NSImageView` brukes uten
  overstyring. Bruk `FlexibleImageView`-subklassen i `main.swift` som
  setter `intrinsicContentSize = noIntrinsicMetric`.
- **Endring av AppIcon.icns alene oppdaterer ikke Dock/Finder.** macOS
  cacher per `CFBundleIdentifier`. Hvis cache henger igjen, øk
  `CFBundleVersion` eller bytt bundle-ID.
- **Quarantine-attributtet** stopper ad-hoc-signerte apper sendt via
  Slack/AirDrop på macOS 15+. Mottakere må kjøre
  `xattr -cr "Gimme SVG.app"`.

## Brukerens kontekst

- Bedrifts-Mac (Bouvet) – ingen admin-rettigheter
- Apple Silicon (`arm64`) – ikke bygd Universal
- Foretrekker native løsninger fremfor web-baserte
- Lim inn URL → grid med previews → multi-select → last ned er den
  ønskede flyten

## Kodekonvensjoner

- Norsk i UI-strenger, kommentarer og dokumentasjon
- Engelske identifikatorer (variabler, funksjoner, typer)
- 4 spaces indentasjon (Swift-default)
- Foretrekk innebygde Apple-API-er fremfor å trekke inn pakker

## Hvor finner jeg

- App-skjelett, vinduet, menyen → bunnen av `main.swift` (`AppDelegate`)
- UI / SwiftUI-views → `ContentView`, `SVGCard`, `SVGPreview` i `main.swift`
- HTML/SVG-parsing → `enum SVGExtractor` i `main.swift`
- Ikon-bygging fra PNG → `build.sh` (sips + iconutil)
- Ikon-bygging fra SVG → `Sources/build_resources.swift` (WKWebView-snapshot,
  brukes ikke av `build.sh` p.t. men beholdt som reserve)
