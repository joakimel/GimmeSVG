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

## Endringer etter v1

Dette dokumenterer iterasjonene gjort etter den opprinnelige commiten
(`065e24f Initial commit`).

### Logo og ikon: v1 → v2 → v3

v1 brukte enkle `app-icon.png` + `logo.svg`/`logo-full.svg`. v2
introduserte `gs_*_v2.svg` med Google Sans Flex-font referert via
`@font-face`-navn. Det fungerte ikke pålitelig fordi:

- Fonten er ikke installert standard på alle Mac-er, så tekst falt
  tilbake til system-fonter med ulik rendring.
- `NSImage`s SVG-renderer behandler tekst inkonsistent med Safari og
  designerens forhåndsvisning.

v3 løste dette ved å konvertere all tekst til paths (outlinet i
designprogrammet). Resultatet rendrer pikselperfekt overalt.

For headeren trengs en hvit-versjon (svart-på-lilla blir uleselig).
Tilnærmingen er minimal:

```bash
sed 's|<svg |<svg fill="#ffffff" |' \
  Resources/gs_full_logo_v3.svg \
  > Resources/gs_full_logo_v3_white.svg
```

Siden v3-paths ikke har egne `fill`-attributter arves fargen via SVG-arv.

App-ikonet `gs_appicon_v3.png` er 880×880 (kvadratisk) og kjøres
gjennom `sips -z 1024 1024` til alle iconset-størrelser.

### Lokalisering – 9 språk i én fil

Vi vurderte et `.lproj`-mappehierarki med `Localizable.strings`, men det
matcher dårlig med single-file-appen og krever Xcode-byggesteg. I stedet:

- `enum AppLanguage` har én case per språk (no, en, de, fr, es, sv, da,
  zh, ja) med `displayName` og `localeIdentifier`.
- `struct Strings` har én computed property eller funksjon per UI-streng
  med en `switch`-blokk over alle språk. Type-sikkert: legger du til et
  nytt språk får du compile-feil på alle ulokaliserte strenger.
- `AppLanguage.detectFromSystem()` itererer `Locale.preferredLanguages`
  og mapper språkprefikser. Faller tilbake til engelsk – ikke norsk –
  fordi appens default-bruker ikke nødvendigvis er norsk.
- Valg lagres i `UserDefaults` under `GimmeSVG.language`. Auto-detect
  skjer kun når nøkkelen ikke finnes.

Tradeoff: `main.swift` vokser, men hele oversettelseskildekoden ligger
i én fil og er trivielt å diffe og refaktorere. For ~30 strenger × 9
språk holder det fint.

### Historikk-cache

Søkene caches komplett (URL + tidspunkt + alle SVG-er) i
`~/Library/Application Support/Gimme SVG/history.json`. Maks 10 entries,
nyeste først. Samme URL erstatter gammelt innslag fremfor å duplisere.

Begrunnelse: «Se resultater»-knappen i historikk-tab skal være øyeblikkelig
og fungere offline. Disk-bruk i praksis: noen MB selv ved tunge sider.

`AppState` setter `didSet` på `history`-property som skriver JSON til
disk. `clearHistory()` setter den til tom array, som trigger samme save.

### Tabs og app-state

Hele app-tilstanden (språk, historikk, aktiv tab) sentraliseres i
`class AppState: ObservableObject`. AppDelegate eier instansen og
injiserer den via `.environmentObject(appState)`. Det lar
`LanguagePicker`, `HistoryListView` og `ContentView` lese/skrive samme
state uten propagation gjennom view-hierarkiet.

Menyen i menybaren (Cmd+Q m.m.) lokaliseres via en Combine-subscription
på `appState.$language` som kaller `rebuildMenu()` ved hvert språkbytte.

### Språkvelger – hvorfor `Menu` ikke fungerte

Første implementasjon brukte SwiftUI-`Menu` med `.menuStyle(.borderlessButton)`
og en label med `.background(Capsule().fill(Color.white))`. På macOS
stripper menystylen bakgrunn og skygge fra labelen – kun tekst og ikon
overlever.

Løsningen ble en vanlig `Button` som veksler en `@State`-variabel og
viser `.popover`. Det gir full kontroll over labelens utseende og
popoverens radvisning, og krever ikke ekstra rammeverk.

### Robustere HTML-parsing

For å gå fra «funker for kjente sider» til «funker for vilkårlig nett»:

1. **Pre-prosessering** fjerner HTML-kommentarer (`<!-- … -->`) og
   `<script>…</script>` før parsing. Disse inneholder ofte SVG-strenger
   som ikke skal fanges.
2. **Stack-basert finder for inline SVG** teller åpne/lukkede `<svg>`-tagger
   så nested SVG håndteres riktig. Tidligere non-greedy regex stoppet
   ved første `</svg>` og kunne returnere ufullstendige blokker.
3. **Selvlukkende `<svg .../>`** ignoreres – de er tomme uansett.
4. **`<style>` beholdes** fordi CSS `url(*.svg)` er en gyldig kilde og
   plukkes opp i en egen pass.

Vi vurderte WKWebView-DOM eller `XMLParser`. Begge er overkill: WKWebView
trenger asynkron lasting og JS-bridge, og HTML er sjelden gyldig XML
som `XMLParser` krever.

### App Store – hva som mangler hvis det skal publiseres

Per i dag er appen ad-hoc signert. For App Store-distribusjon trengs:

1. **Apple Developer Program-medlemskap** (~999 NOK/år).
2. **Full kodesignatur** med Developer ID Application-sertifikat
   (ikke ad-hoc).
3. **App Sandbox** aktivert med entitlements:
   - `com.apple.security.app-sandbox = true`
   - `com.apple.security.network.client = true` (for `URLSession`)
   - `com.apple.security.files.user-selected.read-write = true` (for
     `NSOpenPanel`-mappevalg)
4. **Hardened Runtime** + notarisering (`xcrun notarytool submit`).
5. **`NSAppTransportSecurity`** revurderes – `NSAllowsArbitraryLoads`
   må enten begrunnes eller byttes til `NSAllowsArbitraryLoadsInWebContent`
   eller fjernes helt. App Store Review godtar sjelden carte-blanche
   ATS-bypass uten god grunn.
6. **App Store Connect-record** med ikoner i alle påkrevde størrelser,
   skjermbilder, beskrivelse, kategori (sannsynligvis Utilities eller
   Developer Tools).
7. **Vurder** om Apple kan oppfatte appen som «scraping» av andres
   nettsider. Sjekk App Review Guidelines 5.2 (intellektuell
   eiendom) før innsending – vi henter kun offentlige assets fra
   URLer brukeren oppgir, men det kan likevel bli flagget.

Dette er en ikke-triviell migrasjon og krever sannsynligvis et
`Package.swift` eller Xcode-prosjekt for å sette entitlements korrekt.
Ikke gjort i denne iterasjonen.

### Versjonering

`CFBundleShortVersionString` brukes som brukerlesbar versjon
(SemVer-aktig), `CFBundleVersion` som monoton build-teller. Bumpes i
`build.sh`s Info.plist-heredoc. Per nå: 1.3.0 (build 5).
