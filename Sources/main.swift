import Cocoa
import SwiftUI
import WebKit

// MARK: - Model

struct SVGItem: Identifiable, Hashable {
    let id = UUID()
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
        guard let html = String(data: data, encoding: .utf8) else { return [] }

        var items: [SVGItem] = []

        // 1. Inline <svg>...</svg>
        let inlineMatches = matchAll(pattern: #"<svg\b[^>]*>[\s\S]*?</svg>"#, in: html)
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

// MARK: - Views

let purpleStart = Color(red: 0.46, green: 0.20, blue: 0.93)
let purpleEnd   = Color(red: 0.36, green: 0.27, blue: 0.95)
let greenAccent = Color(red: 0.13, green: 0.70, blue: 0.31)

struct ContentView: View {
    @State private var url = ""
    @State private var items: [SVGItem] = []
    @State private var selected: Set<UUID> = []
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var hasSearched = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.0001)
            urlBar
            Divider()
            content
        }
        .background(Color(NSColor.controlBackgroundColor))
        .frame(minWidth: 760, minHeight: 600)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                logoView
                Text("Finn og last ned SVG-bilder fra hvilken som helst nettside")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.92))
            }
            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .background(
            LinearGradient(colors: [purpleStart, purpleEnd],
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

    private var urlBar: some View {
        HStack(spacing: 12) {
            TextField("Lim inn URL (f.eks. https://example.com)", text: $url)
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
                    Text("Søk")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(canSearch ? AnyShapeStyle(
                            LinearGradient(colors: [purpleStart, purpleEnd],
                                           startPoint: .leading, endPoint: .trailing))
                              : AnyShapeStyle(Color.gray.opacity(0.4))))
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
                Text("Henter siden …").foregroundColor(.secondary)
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
                Circle().fill(purpleStart.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 36, weight: .regular))
                    .foregroundColor(purpleStart)
            }
            VStack(spacing: 6) {
                Text("Klar til å finne SVG-filer")
                    .font(.system(size: 17, weight: .semibold))
                Text("Lim inn en URL ovenfor for å komme i gang")
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
            Text("Fant ingen SVGer på den siden")
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
                    Text(allSelected ? "Fjern alle" : "Velg alle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(purpleStart)
                }
                .buttonStyle(.plain)

                Text("\(items.count) SVG-filer funnet")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.leading, 14)

                Spacer()

                Button(action: download) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.to.line")
                        Text("Last ned (\(selected.count))")
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
        if selected.contains(item.id) {
            selected.remove(item.id)
        } else {
            selected.insert(item.id)
        }
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

        Task {
            do {
                let result = try await SVGExtractor.extract(from: u)
                await MainActor.run {
                    items = result
                    selected = Set(result.map { $0.id })
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorText = "Kunne ikke hente siden: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }

    private func download() {
        let toSave = items.filter { selected.contains($0.id) }
        guard !toSave.isEmpty else { return }

        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.title = "Velg mappe"
        panel.prompt = "Lagre"
        panel.message = "Velg en mappe der \(toSave.count) SVG-filer skal lagres."

        panel.begin { resp in
            guard resp == .OK, let folder = panel.url else { return }
            saveAll(toSave, to: folder)
        }
    }

    private func saveAll(_ list: [SVGItem], to folder: URL) {
        var used = Set<String>()
        var saved = 0
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
                saved += 1
            } catch {
                NSLog("Lagring feilet for \(name): \(error)")
            }
        }
        NSWorkspace.shared.activateFileViewerSelecting([folder])
    }
}

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
                    .foregroundColor(isSelected ? purpleStart : Color.gray.opacity(0.45))
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
                .fill(isSelected ? purpleStart.opacity(0.07)
                                 : Color(NSColor.textBackgroundColor)))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? purpleStart : Color.gray.opacity(0.25),
                        lineWidth: isSelected ? 2 : 1))
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }
}

// MARK: - App entry

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let view = ContentView()

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

        // Bygg en standard hovedmeny så Cmd+Q m.m. fungerer
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(
            title: "Avslutt Gimme SVG",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"))
        appMenuItem.submenu = appMenu

        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Rediger")
        editMenu.addItem(NSMenuItem(title: "Klipp ut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Kopier",   action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Lim inn",  action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Velg alt", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
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
