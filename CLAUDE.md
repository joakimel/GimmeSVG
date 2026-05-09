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
- **`accentColor` er reservert** av SwiftUI som view-modifier. Den globale
  konstanten i `main.swift` heter derfor `appAccent`. Ikke gi en farge
  navnet `accentColor` – kompilatoren vil tolke det som metoden og gi
  «cannot convert (Color?) -> some View» rundt om i fila.
- **`Menu` med `.menuStyle(.borderlessButton)` på macOS stripper bort
  `.background`/`.shadow` på label-en.** Språkvelgeren bruker derfor en
  vanlig `Button` + `.popover` med egne radvisninger. Ikke bytt tilbake
  til `Menu` for headers eller andre elementer der pillen må synes.
- **HTML-parsing er regex-basert med stack-finder.** Pre-prosessering
  fjerner `<!-- … -->` og `<script>…</script>` for å unngå falske treff.
  Inline `<svg>…</svg>` finnes med stack-basert teller (ikke non-greedy
  regex), så nested SVG håndteres. CSS `url(*.svg)` plukkes opp – derfor
  beholdes `<style>`-blokker.

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
- App-tilstand (språk, historikk, aktiv tab) → `class AppState` i `main.swift`
  (`ObservableObject`, injiseres med `.environmentObject` av AppDelegate)
- Lokalisering → `enum AppLanguage` (9 språk) + `struct Strings` med én
  `switch`-blokk per UI-streng. `AppLanguage.detectFromSystem()` matcher
  brukerens systemspråk ved første oppstart, faller tilbake til engelsk.
- Persistens av historikk → `~/Library/Application Support/Gimme SVG/history.json`
  (JSON-encodet `[HistoryEntry]`, maks 10 entries, samme URL erstatter
  gammelt innslag i stedet for å duplisere)
- UI / SwiftUI-views → `ContentView`, `SVGCard`, `SVGPreview`,
  `HistoryListView`, `LanguagePicker`, `LanguageRow` i `main.swift`
- HTML/SVG-parsing → `enum SVGExtractor` i `main.swift` (pre-prosessering
  + stack-basert finder for inline SVG, regex for eksterne referanser)
- Ikon-bygging fra PNG → `build.sh` (sips + iconutil) – kilde:
  `Resources/gs_appicon_v3.png`
- Header-logo → `Resources/gs_full_logo_v3_white.svg` (whitened utgave
  av `gs_full_logo_v3.svg`, generert via `sed 's|<svg |<svg fill="#ffffff" |'`)
- Ikon-bygging fra SVG → `Sources/build_resources.swift` (WKWebView-snapshot,
  brukes ikke av `build.sh` p.t. men beholdt som reserve)
