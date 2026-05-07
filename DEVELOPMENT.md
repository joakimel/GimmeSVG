# Utviklingshistorikk

Notater om prosessen med å bygge Gimme SVG. Tatt med fordi flere blindspor
underveis er nyttig kontekst hvis appen skal videreutvikles eller en
lignende app skal bygges.

## Tidslinje av tilnærminger

### 1. Python + tkinter, kjørt direkte
Første forsøk: ren Python-app med `tkinter` for GUI, `requests` +
`beautifulsoup4` for henting og parsing. Pakker installert med
`pip install --user` (ingen admin-rettigheter på korporativ Mac).

**Fungerte i seg selv**, men `tkinter` ser dated ut og er tungvint å
distribuere som «ekte» app. `start.command`-fila for dobbeltklikk holdt
ikke som distribuerbar form.

### 2. Python + tkinter, pakket med PyInstaller
Forsøkte å bygge en ekte `.app`-bundle med PyInstaller (`--windowed`,
`--icon`, ad-hoc signering).

**Resultat:** appen åpnet med tomt vindu. Tcl/Tk-rammeverket ble ikke
korrekt pakket av PyInstaller på arm64 macOS. Kjent issue, og ikke trivielt
å løse uten å rote med PyInstaller-spec-filer.

### 3. Manuell `.app`-bundle som shell-script-wrapper
Lagde `Contents/MacOS/SVGExtractor` som et bash-script som kalte
`/usr/bin/python3 app.py`. System-Python har fungerende `tkinter`, så
dette omgår PyInstaller-problemet.

**Resultat:** vinduet var fortsatt tomt, eller URL-feltet manglet helt.
Litt uklart hvorfor – mistanke om at `aqua`-temaet i `ttk` ikke fungerte
godt sammen med tilpasset tk-styling (egne farger på `tk.Frame` osv.).

### 4. Lokal HTTP-server + nettleser-UI
Helomvending: lot Python kjøre en lokal `http.server` med en pen HTML/CSS/JS
nettside. Backenden gjorde HTML-henting (slik at CORS ikke ble et problem),
nettleseren rendret SVGene. Inkluderte ZIP-nedlasting via `zipfile`-
modulen.

**Fungerte teknisk perfekt**, men brukeren ville ha en ekte native app,
ikke en nettleser-fane.

### 5. SwiftUI-app kompilert med swiftc (denne)
Gikk over til Swift. Med Xcode CLI tools tilgjengelig kunne `swiftc`
kompilere SwiftUI-appen direkte uten et `.xcodeproj`. Brukte
`NSApplication.shared` + `AppDelegate` i stedet for `@main App`-makroen
(enklere fra CLI).

**Fungerte med en gang.** Native UI, fullt kontroll over rendering,
ingen runtime-avhengigheter.

## Designvalg underveis

### Hvorfor ikke `Package.swift` / SPM?
Swift Package Manager er overkill for en single-file-app. `swiftc` med
tre `-framework`-flagg gjør jobben på under 5 sekunder.

### Hvorfor ikke `@main` App-protocol?
SwiftUI's `@main App`-makro krever en spesifikk byggeprosess som er
vanskelig å replikere fra ren `swiftc`. Direkte `NSApplication` +
`NSHostingView(rootView:)` er litt mer kode, men kompilerer rett fram.

### Hvorfor `NSImage` for SVG-previews, men `WKWebView` for ikon-bygging?
- For mange små previews i grid-en er `NSImage` raskt nok og lett.
- For å bygge selve `.icns`-fila trenger vi pikselperfekt rendering av
  én SVG til mange størrelser. `NSImage` taklet ikke alle SVG-features
  i ikonet (kompleks `<defs>`+`<style>`-struktur), så `build_resources.swift`
  bruker `WKWebView`-snapshot i stedet. Mer pålitelig, men tregere.
- For den nåværende appen ble ikonet til slutt levert som ferdig PNG av
  brukeren, så `build_resources.swift` brukes ikke i `build.sh` lenger
  – men er beholdt i Sources/ i tilfelle vi skal bytte til SVG-basert
  ikon igjen.

### Cropping-problemet med brede SVGer
Tidlig versjon viste brede SVGer som overflødde sine grid-celler.
Årsaken: `NSImageView` rapporterer SVG-ens naturlige bredde som
intrinsic content size, og SwiftUI-LazyVGrid respekterte det.
Løst med `FlexibleImageView`-subklassen som returnerer
`noIntrinsicMetric` i begge dimensjoner.

### Ikon-cache-trøbbel
macOS cacher `.app`-ikoner aggressivt. Selv etter å ha endret
`AppIcon.icns`-fila viste Dock og Finder fortsatt det gamle ikonet.
Løsninger som ble prøvd:
- `touch` på `.app` og `.icns` → hjelp for noen, ikke alle
- `killall Dock` / `killall Finder` → hjalp delvis
- `lsregister -f` → hjelp
- Endre `CFBundleIdentifier` → tvinger ny cache-oppføring (mest
  pålitelige fix)

For sikkerhets skyld bruker `Info.plist` nå en ny bundle-identifier
(`no.elden.gimmesvg`) sammenlignet med tidligere forsøk
(`com.user.gimmesvg`).

## Arvet ad-hoc signering

`codesign --force --deep --sign -` lager en ad-hoc-signatur (ingen
sertifikat). macOS godtar det for lokal bruk, men:

- Gatekeeper viser advarsel første gang
- Hvis appen får `com.apple.quarantine`-attributtet (via download eller
  AirDrop) blokkerer macOS Sequoia (15+) den helt. Workaround:
  `xattr -cr "Gimme SVG.app"` etter mottak.
- Notarisering hos Apple krever `Apple Developer Program`-medlemskap
  ($99/år)

Ikke et problem for personlig bruk eller intern deling der mottakere
forstår dette, men en blocker for offentlig distribusjon.

## Det vi lærte (TL;DR)

1. **PyInstaller + tkinter på arm64 macOS er en jungel.** Bruk system-
   Python eller hopp til native.
2. **System-Python tkinter har sine egne quirks.** Egendefinerte farger
   blander seg dårlig med `aqua`-temaet i `ttk`.
3. **`swiftc` fra CLI er mye smidigere enn folk tror.** Hele en enkel
   SwiftUI-app kan ligge i én fil og kompileres på sekunder.
4. **`NSImage`-SVG-støtten er begrenset.** OK for forhåndsvisninger,
   ikke til pikselperfekt asset-bygging.
5. **macOS ikon-cache er treig å overbevise.** Bytt bundle-ID for å
   tvinge frem refresh.
