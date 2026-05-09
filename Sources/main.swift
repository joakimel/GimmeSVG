import Cocoa
import SwiftUI
import WebKit
import Combine

// MARK: - Language

enum AppLanguage: String, Codable, CaseIterable, Hashable {
    case norwegian = "no"
    case english   = "en"
    case german    = "de"
    case french    = "fr"
    case spanish   = "es"
    case swedish   = "sv"
    case danish    = "da"
    case chinese   = "zh"
    case japanese  = "ja"

    var displayName: String {
        switch self {
        case .norwegian: return "Norsk"
        case .english:   return "English"
        case .german:    return "Deutsch"
        case .french:    return "Français"
        case .spanish:   return "Español"
        case .swedish:   return "Svenska"
        case .danish:    return "Dansk"
        case .chinese:   return "中文"
        case .japanese:  return "日本語"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .norwegian: return "nb_NO"
        case .english:   return "en_US"
        case .german:    return "de_DE"
        case .french:    return "fr_FR"
        case .spanish:   return "es_ES"
        case .swedish:   return "sv_SE"
        case .danish:    return "da_DK"
        case .chinese:   return "zh_Hans"
        case .japanese:  return "ja_JP"
        }
    }

    /// Velger appens språk basert på brukerens systeminnstillinger.
    /// Faller tilbake til engelsk hvis ingen av appens språk matcher.
    static func detectFromSystem() -> AppLanguage {
        for code in Locale.preferredLanguages {
            let primary = code.split(separator: "-").first.map(String.init)?.lowercased() ?? ""
            switch primary {
            case "no", "nb", "nn": return .norwegian
            case "en":             return .english
            case "de":             return .german
            case "fr":             return .french
            case "es":             return .spanish
            case "sv":             return .swedish
            case "da":             return .danish
            case "zh":             return .chinese
            case "ja":             return .japanese
            default:               continue
            }
        }
        return .english
    }
}

// MARK: - Localized strings

struct Strings {
    let language: AppLanguage

    var appSubtitle: String {
        switch language {
        case .norwegian: return "Finn og last ned SVG-bilder fra hvilken som helst nettside"
        case .english:   return "Find and download SVG images from any website"
        case .german:    return "Finde und lade SVG-Bilder von jeder Webseite herunter"
        case .french:    return "Trouvez et téléchargez des images SVG depuis n'importe quel site web"
        case .spanish:   return "Encuentra y descarga imágenes SVG de cualquier sitio web"
        case .swedish:   return "Hitta och ladda ner SVG-bilder från vilken webbplats som helst"
        case .danish:    return "Find og download SVG-billeder fra ethvert websted"
        case .chinese:   return "从任何网站查找并下载 SVG 图像"
        case .japanese:  return "あらゆるウェブサイトから SVG 画像を検索してダウンロード"
        }
    }

    var tabSearch: String {
        switch language {
        case .norwegian: return "Søk"
        case .english:   return "Search"
        case .german:    return "Suchen"
        case .french:    return "Rechercher"
        case .spanish:   return "Buscar"
        case .swedish:   return "Sök"
        case .danish:    return "Søg"
        case .chinese:   return "搜索"
        case .japanese:  return "検索"
        }
    }

    var tabHistory: String {
        switch language {
        case .norwegian: return "Historikk"
        case .english:   return "History"
        case .german:    return "Verlauf"
        case .french:    return "Historique"
        case .spanish:   return "Historial"
        case .swedish:   return "Historik"
        case .danish:    return "Historik"
        case .chinese:   return "历史"
        case .japanese:  return "履歴"
        }
    }

    var urlPlaceholder: String {
        switch language {
        case .norwegian: return "Lim inn URL (f.eks. https://example.com)"
        case .english:   return "Paste a URL (e.g. https://example.com)"
        case .german:    return "URL einfügen (z.B. https://example.com)"
        case .french:    return "Coller une URL (ex. https://example.com)"
        case .spanish:   return "Pega una URL (p. ej. https://example.com)"
        case .swedish:   return "Klistra in URL (t.ex. https://example.com)"
        case .danish:    return "Indsæt URL (f.eks. https://example.com)"
        case .chinese:   return "粘贴 URL（例如 https://example.com）"
        case .japanese:  return "URL を貼り付け（例: https://example.com）"
        }
    }

    var searchButton: String { tabSearch }

    var loading: String {
        switch language {
        case .norwegian: return "Henter siden …"
        case .english:   return "Fetching page …"
        case .german:    return "Seite wird geladen …"
        case .french:    return "Chargement de la page …"
        case .spanish:   return "Cargando página …"
        case .swedish:   return "Hämtar sidan …"
        case .danish:    return "Henter siden …"
        case .chinese:   return "正在加载页面 …"
        case .japanese:  return "ページを読み込み中 …"
        }
    }

    func loadFailed(_ underlying: String) -> String {
        switch language {
        case .norwegian: return "Kunne ikke hente siden: \(underlying)"
        case .english:   return "Could not fetch the page: \(underlying)"
        case .german:    return "Seite konnte nicht geladen werden: \(underlying)"
        case .french:    return "Impossible de charger la page : \(underlying)"
        case .spanish:   return "No se pudo cargar la página: \(underlying)"
        case .swedish:   return "Det gick inte att hämta sidan: \(underlying)"
        case .danish:    return "Kunne ikke hente siden: \(underlying)"
        case .chinese:   return "无法加载页面：\(underlying)"
        case .japanese:  return "ページを読み込めませんでした: \(underlying)"
        }
    }

    var emptyTitle: String {
        switch language {
        case .norwegian: return "Klar til å finne SVG-filer"
        case .english:   return "Ready to find SVG files"
        case .german:    return "Bereit, SVG-Dateien zu finden"
        case .french:    return "Prêt à trouver des fichiers SVG"
        case .spanish:   return "Listo para encontrar archivos SVG"
        case .swedish:   return "Redo att hitta SVG-filer"
        case .danish:    return "Klar til at finde SVG-filer"
        case .chinese:   return "准备查找 SVG 文件"
        case .japanese:  return "SVG ファイルを検索する準備ができました"
        }
    }

    var emptySubtitle: String {
        switch language {
        case .norwegian: return "Lim inn en URL ovenfor for å komme i gang"
        case .english:   return "Paste a URL above to get started"
        case .german:    return "Füge oben eine URL ein, um zu beginnen"
        case .french:    return "Collez une URL ci-dessus pour commencer"
        case .spanish:   return "Pega una URL arriba para empezar"
        case .swedish:   return "Klistra in en URL ovan för att komma igång"
        case .danish:    return "Indsæt en URL ovenfor for at komme i gang"
        case .chinese:   return "在上方粘贴 URL 以开始"
        case .japanese:  return "上に URL を貼り付けて開始"
        }
    }

    var noResults: String {
        switch language {
        case .norwegian: return "Fant ingen SVGer på den siden"
        case .english:   return "No SVGs found on that page"
        case .german:    return "Keine SVGs auf dieser Seite gefunden"
        case .french:    return "Aucun SVG trouvé sur cette page"
        case .spanish:   return "No se encontraron SVG en esa página"
        case .swedish:   return "Hittade inga SVG:er på sidan"
        case .danish:    return "Fandt ingen SVG'er på den side"
        case .chinese:   return "在该页面未找到 SVG"
        case .japanese:  return "そのページに SVG が見つかりませんでした"
        }
    }

    var selectAll: String {
        switch language {
        case .norwegian: return "Velg alle"
        case .english:   return "Select all"
        case .german:    return "Alle auswählen"
        case .french:    return "Tout sélectionner"
        case .spanish:   return "Seleccionar todo"
        case .swedish:   return "Välj alla"
        case .danish:    return "Vælg alle"
        case .chinese:   return "全选"
        case .japanese:  return "すべて選択"
        }
    }

    var deselectAll: String {
        switch language {
        case .norwegian: return "Fjern alle"
        case .english:   return "Clear all"
        case .german:    return "Alle abwählen"
        case .french:    return "Tout désélectionner"
        case .spanish:   return "Deseleccionar todo"
        case .swedish:   return "Avmarkera alla"
        case .danish:    return "Fjern alle"
        case .chinese:   return "取消全选"
        case .japanese:  return "すべて解除"
        }
    }

    func foundCount(_ n: Int) -> String {
        switch language {
        case .norwegian: return "\(n) SVG-filer funnet"
        case .english:   return "\(n) SVG files found"
        case .german:    return "\(n) SVG-Dateien gefunden"
        case .french:    return "\(n) fichiers SVG trouvés"
        case .spanish:   return "\(n) archivos SVG encontrados"
        case .swedish:   return "\(n) SVG-filer hittade"
        case .danish:    return "\(n) SVG-filer fundet"
        case .chinese:   return "找到 \(n) 个 SVG 文件"
        case .japanese:  return "\(n) 件の SVG ファイルが見つかりました"
        }
    }

    func downloadButton(_ n: Int) -> String {
        switch language {
        case .norwegian: return "Last ned (\(n))"
        case .english:   return "Download (\(n))"
        case .german:    return "Herunterladen (\(n))"
        case .french:    return "Télécharger (\(n))"
        case .spanish:   return "Descargar (\(n))"
        case .swedish:   return "Ladda ner (\(n))"
        case .danish:    return "Download (\(n))"
        case .chinese:   return "下载 (\(n))"
        case .japanese:  return "ダウンロード (\(n))"
        }
    }

    var savePanelTitle: String {
        switch language {
        case .norwegian: return "Velg mappe"
        case .english:   return "Choose folder"
        case .german:    return "Ordner wählen"
        case .french:    return "Choisir un dossier"
        case .spanish:   return "Elegir carpeta"
        case .swedish:   return "Välj mapp"
        case .danish:    return "Vælg mappe"
        case .chinese:   return "选择文件夹"
        case .japanese:  return "フォルダを選択"
        }
    }

    var savePanelPrompt: String {
        switch language {
        case .norwegian: return "Lagre"
        case .english:   return "Save"
        case .german:    return "Speichern"
        case .french:    return "Enregistrer"
        case .spanish:   return "Guardar"
        case .swedish:   return "Spara"
        case .danish:    return "Gem"
        case .chinese:   return "保存"
        case .japanese:  return "保存"
        }
    }

    func savePanelMessage(_ n: Int) -> String {
        switch language {
        case .norwegian: return "Velg en mappe der \(n) SVG-filer skal lagres."
        case .english:   return "Choose a folder where \(n) SVG files will be saved."
        case .german:    return "Wähle einen Ordner, in dem \(n) SVG-Dateien gespeichert werden."
        case .french:    return "Choisissez un dossier où enregistrer \(n) fichiers SVG."
        case .spanish:   return "Elige una carpeta donde guardar \(n) archivos SVG."
        case .swedish:   return "Välj en mapp där \(n) SVG-filer ska sparas."
        case .danish:    return "Vælg en mappe hvor \(n) SVG-filer skal gemmes."
        case .chinese:   return "选择保存 \(n) 个 SVG 文件的文件夹。"
        case .japanese:  return "\(n) 件の SVG ファイルを保存するフォルダを選択してください。"
        }
    }

    var historyTitle: String {
        switch language {
        case .norwegian: return "Søkehistorikk"
        case .english:   return "Search history"
        case .german:    return "Suchverlauf"
        case .french:    return "Historique de recherche"
        case .spanish:   return "Historial de búsqueda"
        case .swedish:   return "Sökhistorik"
        case .danish:    return "Søgehistorik"
        case .chinese:   return "搜索历史"
        case .japanese:  return "検索履歴"
        }
    }

    var historyEmpty: String {
        switch language {
        case .norwegian: return "Ingen søk ennå – gjør et søk for å se det her."
        case .english:   return "No searches yet – run a search to see it here."
        case .german:    return "Noch keine Suchen – führe eine Suche aus, um sie hier zu sehen."
        case .french:    return "Aucune recherche pour l'instant – effectuez une recherche pour la voir ici."
        case .spanish:   return "Aún no hay búsquedas – realiza una búsqueda para verla aquí."
        case .swedish:   return "Inga sökningar ännu – gör en sökning för att se den här."
        case .danish:    return "Ingen søgninger endnu – lav en søgning for at se den her."
        case .chinese:   return "还没有搜索 – 进行搜索后将在此显示。"
        case .japanese:  return "まだ検索はありません – 検索を実行するとここに表示されます。"
        }
    }

    var viewResults: String {
        switch language {
        case .norwegian: return "Se resultater"
        case .english:   return "View results"
        case .german:    return "Ergebnisse anzeigen"
        case .french:    return "Voir les résultats"
        case .spanish:   return "Ver resultados"
        case .swedish:   return "Visa resultat"
        case .danish:    return "Se resultater"
        case .chinese:   return "查看结果"
        case .japanese:  return "結果を表示"
        }
    }

    var clearHistoryButton: String {
        switch language {
        case .norwegian: return "Tøm historikk"
        case .english:   return "Clear history"
        case .german:    return "Verlauf löschen"
        case .french:    return "Effacer l'historique"
        case .spanish:   return "Borrar historial"
        case .swedish:   return "Rensa historik"
        case .danish:    return "Ryd historik"
        case .chinese:   return "清除历史"
        case .japanese:  return "履歴を消去"
        }
    }

    var clearHistoryTitle: String {
        switch language {
        case .norwegian: return "Tøm hele historikken?"
        case .english:   return "Clear all history?"
        case .german:    return "Gesamten Verlauf löschen?"
        case .french:    return "Effacer tout l'historique ?"
        case .spanish:   return "¿Borrar todo el historial?"
        case .swedish:   return "Rensa hela historiken?"
        case .danish:    return "Ryd hele historikken?"
        case .chinese:   return "清除所有历史？"
        case .japanese:  return "すべての履歴を消去しますか？"
        }
    }

    var clearHistoryMessage: String {
        switch language {
        case .norwegian: return "Alle lagrede søk og tilhørende SVG-filer slettes permanent. Dette kan ikke angres."
        case .english:   return "All saved searches and their SVG files will be permanently deleted. This cannot be undone."
        case .german:    return "Alle gespeicherten Suchen und zugehörigen SVG-Dateien werden unwiderruflich gelöscht."
        case .french:    return "Toutes les recherches enregistrées et leurs fichiers SVG seront supprimés définitivement. Cette action est irréversible."
        case .spanish:   return "Todas las búsquedas guardadas y sus archivos SVG se eliminarán permanentemente. Esto no se puede deshacer."
        case .swedish:   return "Alla sparade sökningar och tillhörande SVG-filer raderas permanent. Detta kan inte ångras."
        case .danish:    return "Alle gemte søgninger og tilhørende SVG-filer slettes permanent. Dette kan ikke fortrydes."
        case .chinese:   return "所有已保存的搜索及其 SVG 文件将被永久删除。此操作无法撤销。"
        case .japanese:  return "保存されたすべての検索とその SVG ファイルが完全に削除されます。この操作は元に戻せません。"
        }
    }

    var clearHistoryConfirm: String {
        switch language {
        case .norwegian: return "Slett"
        case .english:   return "Delete"
        case .german:    return "Löschen"
        case .french:    return "Supprimer"
        case .spanish:   return "Eliminar"
        case .swedish:   return "Radera"
        case .danish:    return "Slet"
        case .chinese:   return "删除"
        case .japanese:  return "削除"
        }
    }

    var cancelButton: String {
        switch language {
        case .norwegian: return "Avbryt"
        case .english:   return "Cancel"
        case .german:    return "Abbrechen"
        case .french:    return "Annuler"
        case .spanish:   return "Cancelar"
        case .swedish:   return "Avbryt"
        case .danish:    return "Annullér"
        case .chinese:   return "取消"
        case .japanese:  return "キャンセル"
        }
    }

    func svgsLabel(_ n: Int) -> String {
        switch language {
        case .norwegian: return "\(n) SVGs"
        case .english:   return "\(n) SVGs"
        case .german:    return "\(n) SVGs"
        case .french:    return "\(n) SVG"
        case .spanish:   return "\(n) SVG"
        case .swedish:   return "\(n) SVG:er"
        case .danish:    return "\(n) SVG'er"
        case .chinese:   return "\(n) 个 SVG"
        case .japanese:  return "\(n) SVG"
        }
    }

    func formatTimestamp(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: language.localeIdentifier)
        f.setLocalizedDateFormatFromTemplate("d MMM, HH:mm")
        return f.string(from: date)
    }

    var menuQuit: String {
        switch language {
        case .norwegian: return "Avslutt Gimme SVG"
        case .english:   return "Quit Gimme SVG"
        case .german:    return "Gimme SVG beenden"
        case .french:    return "Quitter Gimme SVG"
        case .spanish:   return "Salir de Gimme SVG"
        case .swedish:   return "Avsluta Gimme SVG"
        case .danish:    return "Afslut Gimme SVG"
        case .chinese:   return "退出 Gimme SVG"
        case .japanese:  return "Gimme SVG を終了"
        }
    }

    var menuEdit: String {
        switch language {
        case .norwegian: return "Rediger"
        case .english:   return "Edit"
        case .german:    return "Bearbeiten"
        case .french:    return "Édition"
        case .spanish:   return "Editar"
        case .swedish:   return "Redigera"
        case .danish:    return "Rediger"
        case .chinese:   return "编辑"
        case .japanese:  return "編集"
        }
    }

    var menuCut: String {
        switch language {
        case .norwegian: return "Klipp ut"
        case .english:   return "Cut"
        case .german:    return "Ausschneiden"
        case .french:    return "Couper"
        case .spanish:   return "Cortar"
        case .swedish:   return "Klipp ut"
        case .danish:    return "Klip"
        case .chinese:   return "剪切"
        case .japanese:  return "カット"
        }
    }

    var menuCopy: String {
        switch language {
        case .norwegian: return "Kopier"
        case .english:   return "Copy"
        case .german:    return "Kopieren"
        case .french:    return "Copier"
        case .spanish:   return "Copiar"
        case .swedish:   return "Kopiera"
        case .danish:    return "Kopier"
        case .chinese:   return "复制"
        case .japanese:  return "コピー"
        }
    }

    var menuPaste: String {
        switch language {
        case .norwegian: return "Lim inn"
        case .english:   return "Paste"
        case .german:    return "Einfügen"
        case .french:    return "Coller"
        case .spanish:   return "Pegar"
        case .swedish:   return "Klistra in"
        case .danish:    return "Indsæt"
        case .chinese:   return "粘贴"
        case .japanese:  return "ペースト"
        }
    }

    var menuSelectAll: String {
        switch language {
        case .norwegian: return "Velg alt"
        case .english:   return "Select all"
        case .german:    return "Alles auswählen"
        case .french:    return "Tout sélectionner"
        case .spanish:   return "Seleccionar todo"
        case .swedish:   return "Markera allt"
        case .danish:    return "Vælg alt"
        case .chinese:   return "全选"
        case .japanese:  return "すべて選択"
        }
    }

    var languagePickerLabel: String {
        switch language {
        case .norwegian: return "Språk"
        case .english:   return "Language"
        case .german:    return "Sprache"
        case .french:    return "Langue"
        case .spanish:   return "Idioma"
        case .swedish:   return "Språk"
        case .danish:    return "Sprog"
        case .chinese:   return "语言"
        case .japanese:  return "言語"
        }
    }
}

// MARK: - Model

struct SVGItem: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var filename: String
    let content: String
    let kind: String
    let sourceURL: String?

    var sizeBytes: Int { content.utf8.count }
    var sizeString: String {
        let n = sizeBytes
        if n < 1024 { return "\(n) B" }
        if n < 1024 * 1024 { return String(format: "%.1f KB", Double(n) / 1024.0) }
        return String(format: "%.1f MB", Double(n) / 1_048_576.0)
    }
}

struct HistoryEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    let url: String
    let timestamp: Date
    let items: [SVGItem]
}

// MARK: - App state

enum AppTab: Hashable { case search, history }

final class AppState: ObservableObject {
    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.languageKey)
        }
    }
    @Published var history: [HistoryEntry] {
        didSet { saveHistory() }
    }
    @Published var currentTab: AppTab = .search

    private static let languageKey = "GimmeSVG.language"
    private static let historyLimit = 10

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.languageKey),
           let lang = AppLanguage(rawValue: raw) {
            self.language = lang
        } else {
            self.language = AppLanguage.detectFromSystem()
        }
        self.history = Self.loadHistory()
    }

    var strings: Strings { Strings(language: language) }

    func recordSearch(url: String, items: [SVGItem]) {
        let entry = HistoryEntry(url: url, timestamp: Date(), items: items)
        var next = history
        next.removeAll { $0.url == url }
        next.insert(entry, at: 0)
        if next.count > Self.historyLimit {
            next = Array(next.prefix(Self.historyLimit))
        }
        history = next
    }

    func clearHistory() {
        history = []
    }

    // MARK: persistence

    private static func historyFileURL() throws -> URL {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = support.appendingPathComponent("Gimme SVG", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("history.json")
    }

    private func saveHistory() {
        do {
            let url = try Self.historyFileURL()
            let data = try JSONEncoder().encode(history)
            try data.write(to: url, options: .atomic)
        } catch {
            NSLog("Kunne ikke lagre historikk: \(error)")
        }
    }

    private static func loadHistory() -> [HistoryEntry] {
        guard let url = try? historyFileURL(),
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([HistoryEntry].self, from: data)
        else { return [] }
        return entries
    }
}

// MARK: - Extractor

enum SVGExtractor {

    static func extract(from urlString: String) async throws -> [SVGItem] {
        guard let baseURL = URL(string: urlString) else {
            throw NSError(domain: "Gimme", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Ugyldig URL"])
        }

        var req = URLRequest(url: baseURL)
        req.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
            + "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 20

        let (data, _) = try await URLSession.shared.data(for: req)
        guard let rawHTML = String(data: data, encoding: .utf8) else { return [] }
        // Fjern HTML-kommentarer og <script>-blokker som ofte inneholder
        // SVG-strenger som ikke skal fanges. <style> beholdes – CSS kan
        // referere SVG-er via url(...) og vi vil ha med dem.
        let html = stripHTMLNoise(rawHTML)

        var items: [SVGItem] = []

        // 1. Inline <svg>...</svg> – stack-basert finder så nested <svg>
        // i samme blokk håndteres riktig (non-greedy regex stoppet for tidlig).
        let inlineMatches = findInlineSVGs(in: html)
        for (i, raw) in inlineMatches.enumerated() {
            let id = matchFirst(pattern: #"id\s*=\s*["']([^"']+)["']"#, in: raw, group: 1)
            let aria = matchFirst(pattern: #"aria-label\s*=\s*["']([^"']+)["']"#, in: raw, group: 1)
            let baseName = id ?? aria ?? "svg-\(i + 1)"
            let safe = sanitize(baseName) + ".svg"
            items.append(SVGItem(filename: safe, content: raw, kind: "inline", sourceURL: nil))
        }

        // 2. External SVG references
        var seen = Set<String>()

        func resolve(_ s: String) -> URL? {
            URL(string: s, relativeTo: baseURL)?.absoluteURL
        }

        func collect(_ urls: [String], kind: String) async {
            for s in urls {
                let cleaned = String(s.split(separator: "#").first ?? "")
                guard !cleaned.isEmpty,
                      let resolved = resolve(cleaned)?.absoluteString,
                      !seen.contains(resolved) else { continue }
                seen.insert(resolved)
                if let item = await fetchExternal(urlString: resolved, kind: kind) {
                    items.append(item)
                }
            }
        }

        await collect(
            matchAll(pattern: #"<img\b[^>]*\bsrc\s*=\s*["']([^"']+\.svg[^"']*)["']"#,
                     in: html, group: 1),
            kind: "img")

        await collect(
            matchAll(pattern: #"<object\b[^>]*\bdata\s*=\s*["']([^"']+\.svg[^"']*)["']"#,
                     in: html, group: 1),
            kind: "object")

        await collect(
            matchAll(pattern: #"<use\b[^>]*\b(?:xlink:)?href\s*=\s*["']([^"']+\.svg[^"']*)["']"#,
                     in: html, group: 1),
            kind: "use")

        await collect(
            matchAll(pattern: #"url\(["']?([^"')\s]+\.svg[^"')\s]*)["']?\)"#,
                     in: html, group: 1),
            kind: "css")

        await collect(
            matchAll(pattern: #"<a\b[^>]*\bhref\s*=\s*["']([^"']+\.svg[^"']*)["']"#,
                     in: html, group: 1),
            kind: "link")

        return items
    }

    static func fetchExternal(urlString: String, kind: String) async -> SVGItem? {
        guard let url = URL(string: urlString) else { return nil }
        var req = URLRequest(url: url)
        req.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
            forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 12
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 { return nil }
            guard let content = String(data: data, encoding: .utf8) else { return nil }
            var name = url.lastPathComponent
            if name.isEmpty { name = "external.svg" }
            if !name.lowercased().hasSuffix(".svg") { name += ".svg" }
            return SVGItem(filename: name, content: content, kind: kind, sourceURL: urlString)
        } catch {
            return nil
        }
    }

    // MARK: HTML pre-prosessering

    private static func stripHTMLNoise(_ html: String) -> String {
        var s = html
        s = s.replacingOccurrences(
            of: #"<!--[\s\S]*?-->"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(
            of: #"<script\b[^>]*>[\s\S]*?</script>"#,
            with: "", options: [.regularExpression, .caseInsensitive])
        return s
    }

    /// Finn alle inline `<svg>...</svg>`-blokker, inkludert blokker som
    /// inneholder nested `<svg>`. Selvlukkende `<svg .../>` ignoreres
    /// fordi de er tomme.
    private static func findInlineSVGs(in html: String) -> [String] {
        var results: [String] = []
        var i = html.startIndex

        while i < html.endIndex {
            guard let openMatch = html.range(
                of: #"(?i)<svg\b"#, options: .regularExpression,
                range: i..<html.endIndex) else { break }

            guard let gt = html.range(of: ">", range: openMatch.upperBound..<html.endIndex) else {
                break
            }
            let openTagEnd = gt.upperBound
            let openTag = html[openMatch.lowerBound..<openTagEnd]
            if openTag.hasSuffix("/>") {
                i = openTagEnd
                continue
            }

            var depth = 1
            var cursor = openTagEnd
            var blockEnd: String.Index?

            while cursor < html.endIndex {
                let nextOpen = html.range(
                    of: #"(?i)<svg\b"#, options: .regularExpression,
                    range: cursor..<html.endIndex)
                guard let nextClose = html.range(
                    of: "</svg>", options: .caseInsensitive,
                    range: cursor..<html.endIndex) else { break }

                if let openR = nextOpen, openR.lowerBound < nextClose.lowerBound {
                    depth += 1
                    cursor = openR.upperBound
                } else {
                    depth -= 1
                    if depth == 0 {
                        blockEnd = nextClose.upperBound
                        break
                    }
                    cursor = nextClose.upperBound
                }
            }

            if let end = blockEnd {
                results.append(String(html[openMatch.lowerBound..<end]))
                i = end
            } else {
                i = openTagEnd
            }
        }
        return results
    }

    // MARK: regex helpers

    static func matchAll(pattern: String, in text: String, group: Int = 0) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { m in
            guard m.numberOfRanges > group,
                  let r = Range(m.range(at: group), in: text) else { return nil }
            return String(text[r])
        }
    }

    static func matchFirst(pattern: String, in text: String, group: Int) -> String? {
        matchAll(pattern: pattern, in: text, group: group).first
    }

    static func sanitize(_ name: String) -> String {
        let cleaned = name.replacingOccurrences(
            of: #"[^\w\-.]"#, with: "_", options: .regularExpression)
        return cleaned.isEmpty ? "svg" : cleaned
    }
}

// MARK: - SVG Preview

/// NSImageView som ikke rapporterer SVG-ens naturlige størrelse som intrinsic
/// content size – ellers ville brede SVGer sprenge layouten i SwiftUI.
final class FlexibleImageView: NSImageView {
    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
    }
}

struct SVGPreview: NSViewRepresentable {
    let content: String

    func makeNSView(context: Context) -> FlexibleImageView {
        let v = FlexibleImageView()
        v.imageScaling = .scaleProportionallyUpOrDown
        v.imageAlignment = .alignCenter
        v.wantsLayer = true
        v.layer?.masksToBounds = true
        v.setContentHuggingPriority(.init(1), for: .horizontal)
        v.setContentHuggingPriority(.init(1), for: .vertical)
        v.setContentCompressionResistancePriority(.init(1), for: .horizontal)
        v.setContentCompressionResistancePriority(.init(1), for: .vertical)
        v.image = makeImage()
        return v
    }

    func updateNSView(_ view: FlexibleImageView, context: Context) {
        view.image = makeImage()
    }

    private func makeImage() -> NSImage? {
        guard let data = content.data(using: .utf8) else { return nil }
        return NSImage(data: data)
    }
}

// MARK: - Colors

let headerStart  = Color(red: 0.20, green: 0.32, blue: 0.95)   // blå
let headerEnd    = Color(red: 0.55, green: 0.25, blue: 0.95)   // lilla
let appAccent  = Color(red: 0.10, green: 0.32, blue: 0.95)   // blå aksent
let greenAccent  = Color(red: 0.13, green: 0.70, blue: 0.31)
let badgeYellow  = Color(red: 1.00, green: 0.78, blue: 0.20)
let badgeYellowBg = Color(red: 1.00, green: 0.94, blue: 0.74)

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    @State private var url = ""
    @State private var items: [SVGItem] = []
    @State private var selected: Set<UUID> = []
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var hasSearched = false

    private var s: Strings { appState.strings }

    var body: some View {
        VStack(spacing: 0) {
            header
            tabBar
            Group {
                if appState.currentTab == .search {
                    searchBody
                } else {
                    HistoryListView(onOpen: openHistoryEntry)
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .frame(minWidth: 760, minHeight: 600)
    }

    // MARK: header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 12) {
                logoView
                Text(s.appSubtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.92))
            }
            Spacer()
            LanguagePicker()
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .background(
            LinearGradient(colors: [headerStart, headerEnd],
                           startPoint: .leading, endPoint: .trailing))
    }

    @ViewBuilder
    private var logoView: some View {
        if let url = Bundle.main.url(forResource: "logo", withExtension: "svg"),
           let img = NSImage(contentsOf: url) {
            Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 60)
        } else {
            Text("Gimme SVG")
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(.white)
        }
    }

    // MARK: tabs

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(.search, label: s.tabSearch, icon: "magnifyingglass", badgeCount: 0)
            tabButton(.history, label: s.tabHistory, icon: "clock", badgeCount: appState.history.count)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.gray.opacity(0.18)).frame(height: 1)
        }
    }

    private func tabButton(_ tab: AppTab, label: String, icon: String, badgeCount: Int) -> some View {
        let isActive = appState.currentTab == tab
        return Button {
            appState.currentTab = tab
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 14))
                Text(label).font(.system(size: 14, weight: .semibold))
                if badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black.opacity(0.78))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(badgeYellow))
                }
            }
            .foregroundColor(isActive ? appAccent : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.clear)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(isActive ? appAccent : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: search body

    @ViewBuilder
    private var searchBody: some View {
        VStack(spacing: 0) {
            urlBar
            Divider()
            content
        }
    }

    private var urlBar: some View {
        HStack(spacing: 12) {
            TextField(s.urlPlaceholder, text: $url)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.28), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.textBackgroundColor)))
                )
                .onSubmit { search() }

            Button(action: search) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                    Text(s.searchButton)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(canSearch
                              ? appAccent
                              : Color(red: 0.55, green: 0.62, blue: 0.85)))
            }
            .buttonStyle(.plain)
            .disabled(!canSearch)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .background(Color(NSColor.controlBackgroundColor))
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 14) {
                ProgressView().controlSize(.large)
                Text(s.loading).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let err = errorText {
            errorView(err)
        } else if !hasSearched {
            emptyState
        } else if items.isEmpty {
            noResultsState
        } else {
            resultsView
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(appAccent.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 36, weight: .regular))
                    .foregroundColor(appAccent)
            }
            VStack(spacing: 6) {
                Text(s.emptyTitle)
                    .font(.system(size: 17, weight: .semibold))
                Text(s.emptySubtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text(s.noResults)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            Text(msg)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultsView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: toggleSelectAll) {
                    Text(allSelected ? s.deselectAll : s.selectAll)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(appAccent)
                }
                .buttonStyle(.plain)

                Text(s.foundCount(items.count))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.leading, 14)

                Spacer()

                Button(action: download) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.to.line")
                        Text(s.downloadButton(selected.count))
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selected.isEmpty ? Color.gray : greenAccent))
                }
                .buttonStyle(.plain)
                .disabled(selected.isEmpty)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 18)

            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 200, maximum: 260), spacing: 14)],
                    spacing: 14
                ) {
                    ForEach(items) { item in
                        SVGCard(
                            item: item,
                            isSelected: selected.contains(item.id),
                            onToggle: { toggle(item) }
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: actions

    private var canSearch: Bool {
        !url.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading
    }

    private var allSelected: Bool {
        !items.isEmpty && selected.count == items.count
    }

    private func toggle(_ item: SVGItem) {
        if selected.contains(item.id) { selected.remove(item.id) }
        else { selected.insert(item.id) }
    }

    private func toggleSelectAll() {
        if allSelected { selected.removeAll() }
        else { selected = Set(items.map { $0.id }) }
    }

    private func search() {
        var u = url.trimmingCharacters(in: .whitespaces)
        guard !u.isEmpty else { return }
        if !u.lowercased().hasPrefix("http://") && !u.lowercased().hasPrefix("https://") {
            u = "https://" + u
            url = u
        }

        items = []
        selected = []
        errorText = nil
        isLoading = true
        hasSearched = true

        let searchURL = u

        Task {
            do {
                let result = try await SVGExtractor.extract(from: searchURL)
                await MainActor.run {
                    items = result
                    selected = Set(result.map { $0.id })
                    isLoading = false
                    if !result.isEmpty {
                        appState.recordSearch(url: searchURL, items: result)
                    }
                }
            } catch {
                await MainActor.run {
                    errorText = s.loadFailed(error.localizedDescription)
                    isLoading = false
                }
            }
        }
    }

    private func openHistoryEntry(_ entry: HistoryEntry) {
        url = entry.url
        items = entry.items
        selected = Set(entry.items.map { $0.id })
        errorText = nil
        isLoading = false
        hasSearched = true
        appState.currentTab = .search
    }

    private func download() {
        let toSave = items.filter { selected.contains($0.id) }
        guard !toSave.isEmpty else { return }

        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.title = s.savePanelTitle
        panel.prompt = s.savePanelPrompt
        panel.message = s.savePanelMessage(toSave.count)

        panel.begin { resp in
            guard resp == .OK, let folder = panel.url else { return }
            saveAll(toSave, to: folder)
        }
    }

    private func saveAll(_ list: [SVGItem], to folder: URL) {
        var used = Set<String>()
        for item in list {
            var name = item.filename
            if used.contains(name) {
                let nsName = name as NSString
                let base = nsName.deletingPathExtension
                let ext  = nsName.pathExtension.isEmpty ? "svg" : nsName.pathExtension
                var i = 1
                var candidate = "\(base)_\(i).\(ext)"
                while used.contains(candidate) { i += 1; candidate = "\(base)_\(i).\(ext)" }
                name = candidate
            }
            used.insert(name)
            let path = folder.appendingPathComponent(name)
            do {
                try item.content.write(to: path, atomically: true, encoding: .utf8)
            } catch {
                NSLog("Lagring feilet for \(name): \(error)")
            }
        }
        NSWorkspace.shared.activateFileViewerSelecting([folder])
    }
}

// MARK: - Language picker

/// Egenstyrt dropdown – `Menu` med `.menuStyle(.borderlessButton)` på macOS
/// lar OS overstyre `.background` på labelen, så pillen forsvinner.
/// Vi bruker en vanlig knapp + popover for full kontroll over styling.
struct LanguagePicker: View {
    @EnvironmentObject var appState: AppState
    @State private var showMenu = false

    var body: some View {
        Button {
            showMenu.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "globe")
                    .font(.system(size: 17, weight: .semibold))
                Text(appState.language.displayName)
                    .font(.system(size: 15, weight: .bold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.black.opacity(0.55))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(Capsule().fill(Color.white))
            .shadow(color: Color.black.opacity(0.22), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showMenu, arrowEdge: .bottom) {
            VStack(spacing: 0) {
                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    LanguageRow(
                        language: lang,
                        isSelected: lang == appState.language
                    ) {
                        appState.language = lang
                        showMenu = false
                    }
                }
            }
            .padding(.vertical, 4)
            .frame(minWidth: 180)
        }
    }
}

private struct LanguageRow: View {
    let language: AppLanguage
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(language.displayName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(appAccent)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
            .background(hovered ? Color.gray.opacity(0.15) : Color.clear)
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}

// MARK: - History view

struct HistoryListView: View {
    @EnvironmentObject var appState: AppState
    let onOpen: (HistoryEntry) -> Void

    private var s: Strings { appState.strings }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "clock")
                            .font(.system(size: 18))
                            .foregroundColor(appAccent)
                        Text(s.historyTitle)
                            .font(.system(size: 19, weight: .bold))
                    }
                    Spacer()
                    if !appState.history.isEmpty {
                        Button(action: confirmClearHistory) {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text(s.clearHistoryButton)
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color.red.opacity(0.4), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 6)

                if appState.history.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 34))
                            .foregroundColor(.secondary)
                        Text(s.historyEmpty)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 220)
                } else {
                    ForEach(appState.history) { entry in
                        historyCard(entry)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
        }
    }

    private func confirmClearHistory() {
        let alert = NSAlert()
        alert.messageText = s.clearHistoryTitle
        alert.informativeText = s.clearHistoryMessage
        alert.alertStyle = .warning
        alert.addButton(withTitle: s.clearHistoryConfirm)
        alert.addButton(withTitle: s.cancelButton)
        if alert.runModal() == .alertFirstButtonReturn {
            appState.clearHistory()
        }
    }

    private func historyCard(_ entry: HistoryEntry) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(entry.url)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 14) {
                    HStack(spacing: 5) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11))
                        Text(s.svgsLabel(entry.items.count))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.black.opacity(0.78))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(badgeYellowBg))

                    HStack(spacing: 5) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(s.formatTimestamp(entry.timestamp))
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                onOpen(entry)
            } label: {
                Text(s.viewResults)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(appAccent))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.textBackgroundColor)))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.22), lineWidth: 1))
    }
}

// MARK: - SVG Card

struct SVGCard: View {
    let item: SVGItem
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                SVGPreview(content: item.content)
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .frame(height: 130)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                    .clipped()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 19))
                    .foregroundColor(isSelected ? appAccent : Color.gray.opacity(0.45))
                    .background(
                        Circle().fill(.white).frame(width: 19, height: 19))
                    .padding(10)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.filename)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(item.sizeString)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? appAccent.opacity(0.07)
                                 : Color(NSColor.textBackgroundColor)))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? appAccent : Color.gray.opacity(0.25),
                        lineWidth: isSelected ? 2 : 1))
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }
}

// MARK: - App entry

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let appState = AppState()
    private var languageCancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let view = ContentView().environmentObject(appState)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.title = "Gimme SVG"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = false
        window.center()
        window.setFrameAutosaveName("MainWindow")
        window.contentView = NSHostingView(rootView: view)
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)

        rebuildMenu()
        languageCancellable = appState.$language.sink { [weak self] _ in
            DispatchQueue.main.async { self?.rebuildMenu() }
        }
    }

    private func rebuildMenu() {
        let s = appState.strings
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(
            title: s.menuQuit,
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"))
        appMenuItem.submenu = appMenu

        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: s.menuEdit)
        editMenu.addItem(NSMenuItem(title: s.menuCut,       action: #selector(NSText.cut(_:)),       keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: s.menuCopy,      action: #selector(NSText.copy(_:)),      keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: s.menuPaste,     action: #selector(NSText.paste(_:)),     keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: s.menuSelectAll, action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenuItem.submenu = editMenu

        NSApp.mainMenu = mainMenu
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
