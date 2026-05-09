# Gimme SVG

<p align="center">
  <img src="Resources/gs_full_logo_v3.svg" width="260" alt="Gimme SVG logo">
</p>

En liten native Mac-app som finner og laster ned alle SVG-bilder fra en
nettside. Lim inn en URL → trykk Søk → velg ut SVGer du vil ha → last ned.

Bygd i SwiftUI med kun innebygde Apple-rammeverk – ingen tredjeparts
avhengigheter.

**Repo:** https://github.com/joakimel/GimmeSVG

```bash
git clone https://github.com/joakimel/GimmeSVG.git
cd GimmeSVG
./build.sh
open ~/Desktop/"Gimme SVG.app"
```

---

## Funksjoner

- **Henter alt** – inline `<svg>`-tagger (inkl. nested), `<img src="*.svg">`,
  `<object data>`, `<use href>`, CSS-bakgrunner (`url(*.svg)`), og
  direktelenker. HTML-kommentarer og `<script>`-blokker ignoreres så
  ekstrahering blir robust på vilkårlige nettsider.
- **Forhåndsvisning** – hver SVG vises rendret som bilde i et grid
- **Multi-select** – klikk på kort for å velge/avvelge, «Velg alle» for alt
- **Last ned utvalgte** – velg mappe via systemets standard `NSOpenPanel`,
  Finder åpnes automatisk når lagring er ferdig
- **Server-side henting** – appen gjør HTTP-kallene selv, så CORS er ikke
  et problem som ved en ren nettside-løsning
- **9 språk** – norsk, engelsk, tysk, fransk, spansk, svensk, dansk,
  forenklet kinesisk, japansk. Settes automatisk fra systemspråket ved
  første oppstart, kan overstyres via språkvelgeren i headeren.
- **Søkehistorikk** – de 10 siste søkene huskes med URL, tidspunkt og
  hele SVG-innholdet. «Se resultater» åpner cachen umiddelbart uten
  nytt nettverkskall. «Tøm historikk» med bekreftelse fjerner alt.

## Skjermbilde / design

- Blå-til-lilla gradient-header med whitened v3-logo og en hvit pille for
  språkvelger (globe + språk + chevron) øverst til høyre
- Tab-bar under headeren: «Søk» og «Historikk» (sistnevnte med gult
  badge når det finnes lagrede søk)
- URL-felt + blå «Søk»-knapp med forstørrelsesglass-ikon
- Tom-tilstand med stort blått forstørrelsesglass
- Grid med valgbare kort (blå ramme på valgte)
- Grønn «Last ned (N)»-knapp i øverste høyre hjørne av resultatlista
- Historikk-tab viser søk som kort med URL, antall SVG-er, tidspunkt
  og «Se resultater»-knapp. «Tøm historikk» øverst til høyre.

---

## Mappestruktur

```
Gimme SVG/
├── README.md                          ← denne fila
├── CLAUDE.md                          ← kontekst for AI-assistenter
├── DEVELOPMENT.md                     ← utviklingshistorikk + iterasjoner
├── build.sh                           ← én kommando, bygger ferdig .app
├── Sources/
│   ├── main.swift                     ← hele appen (SwiftUI + AppKit)
│   └── build_resources.swift          ← (valgfri) WKWebView-basert SVG→ikon-bygger
└── Resources/
    ├── gs_appicon_v3.png              ← app-ikon (880×880, brukes av build.sh)
    ├── gs_appicon_v3.svg              ← vector-kilde for ikonet
    ├── gs_full_logo_v3.svg            ← logo (outlinet, ingen font-avhengighet)
    └── gs_full_logo_v3_white.svg      ← whitened logo brukt i header
```

Bygd app havner som standard på `~/Desktop/Gimme SVG.app`.

---

## Bygging

### Krav
- macOS 11+ (Big Sur eller nyere)
- Xcode Command Line Tools (`xcode-select --install`)
- Ingen Xcode-IDE eller pakkebehandlere

### Bygg
```bash
cd "Claude Code Projects/Gimme SVG"
./build.sh
```

Det er det. `build.sh` bruker `swiftc`, `sips`, `iconutil` og `codesign`
– alle innebygd i Xcode CLI tools.

For å bygge til en annen plassering:
```bash
./build.sh /path/to/Gimme\ SVG.app
```

### Første kjøring
macOS Gatekeeper blokkerer ad-hoc-signerte apper:
**Høyreklikk på `.app`-fila → Åpne → Åpne i dialogen som dukker opp**

Etter første gang åpner du den som vanlig.

---

<!--## Tilpasning

### Bytte ikon
Erstatt `Resources/app-icon.png` med en kvadratisk PNG (1024×1024 anbefalt),
deretter `./build.sh` igjen.

### Bytte logo
1. Erstatt `Resources/logo-full.svg` med din nye logo
2. Generer en hvit versjon (alt fyll satt til hvitt):
   ```bash
   python3 -c '
   import re
   src = open("Resources/logo-full.svg").read()
   white = re.sub(r"<defs>.*?</defs>",
       "<defs><style>* { fill: #ffffff !important; }</style></defs>",
       src, flags=re.DOTALL)
   open("Resources/logo.svg", "w").write(white)
   '
   ```
3. `./build.sh`

Hvis logoen din ikke har en `<defs>`-blokk fra start, kan du i stedet
bare manuelt sette `fill="#ffffff"` på rot-`<g>`-elementet.

### Endre farger / layout
Alle farger er definert øverst i `Sources/main.swift`:
```swift
let purpleStart = Color(red: 0.46, green: 0.20, blue: 0.93)
let purpleEnd   = Color(red: 0.36, green: 0.27, blue: 0.95)
let greenAccent = Color(red: 0.13, green: 0.70, blue: 0.31)
```
-->
---

## Tekniske detaljer

### Arkitektur
| Lag | Implementasjon |
|---|---|
| **UI** | SwiftUI (`ContentView`, `SVGCard`, `SVGPreview`, `HistoryListView`, `LanguagePicker`) i `NSHostingView` |
| **App-skall** | Direkte `NSApplication` + `AppDelegate` (ikke `@main`-makro) |
| **App-tilstand** | `class AppState: ObservableObject` for språk, historikk, aktiv tab |
| **Lokalisering** | `enum AppLanguage` + `struct Strings` (9 språk, in-source) |
| **Nettverk** | `URLSession.shared.data(for:)` med async/await |
| **HTML-parsing** | Pre-prosessering (strip kommentarer/script) + stack-basert finder for inline SVG, regex for eksterne referanser |
| **SVG-rendering** | `NSImage(data:)` for previews; `WKWebView`-snapshot for ikon-bygging (reserve) |
| **Lagring** | `NSOpenPanel` for mappevalg, `String.write(to:)` for filer |
| **Persistens** | `UserDefaults` for språk, JSON i `~/Library/Application Support/Gimme SVG/history.json` for historikk |
| **Pakking** | Manuelt bygget `.app`-bundle med `Info.plist`, ad-hoc `codesign` |

### Hvorfor ikke Xcode-prosjekt?
Hele appen kompileres med én `swiftc`-kommando. Ingen `.xcodeproj`,
ingen `Package.swift`, ingen target-konfigurasjon. Kildekoden er én
selvstendig fil og kan leses fra topp til bunn.

### `FlexibleImageView`
SVGer kan ha vilkårlig dimensjon. `NSImageView` rapporterer kildens
naturlige størrelse som intrinsic content size, og uten overstyring vil
en bred SVG sprenge layouten i SwiftUI. Subklassen overrider
`intrinsicContentSize` til `noIntrinsicMetric` i begge dimensjoner, slik
at SwiftUI-grid-en bestemmer størrelsen.

### CORS
Siden appen er native, ikke en nettside, gjelder ikke browser-CORS-regler.
HTTP-kallene går rett ut via `URLSession`. `NSAppTransportSecurity` har
`NSAllowsArbitraryLoads = true` slik at også HTTP (ikke bare HTTPS) og
selvsignerte sertifikater fungerer – nødvendig for å scrape vilkårlige
nettsteder.

---

## Distribusjon

Se også svar på spørsmål om dette i `DEVELOPMENT.md`. Kort oppsummert:

- **Trygt rent teknisk** – appen gjør kun nettverkskall til URL-en brukeren
  oppgir, har ingen telemetri eller persistens, bruker bare Apples egne
  rammeverk
- **Ad-hoc signert** – Gatekeeper viser advarsel første gang. Den er ikke
  notarisert hos Apple
- **Kun arm64** – kjører ikke på Intel-Mac. Bygg evt. universal med
  `swiftc -target arm64-apple-macos11 -target x86_64-apple-macos11`
- **Quarantine-attributt** – ved deling via Slack/AirDrop/email får appen
  `com.apple.quarantine`-merket. Mottakere kan måtte kjøre
  `xattr -cr "Gimme SVG.app"` for å åpne den

**Anbefalt distribusjon internt:** del kildekoden, ikke binæren. Da kan
mottakere bygge selv med `./build.sh`.

---

## Lisens / opphav

Bygd som internt verktøy. Bruk fritt.

