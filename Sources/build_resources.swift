// Bygger Resources for Gimme SVG-appen ved å bruke WKWebView (Safaris renderer).
// Mye mer pålitelig enn NSImage for komplekse SVG-er.
//
// Kjør:  swiftc -O build_resources.swift -o build_resources \
//          -framework Cocoa -framework WebKit
//        ./build_resources [path/to/Gimme SVG.app]

import Cocoa
import WebKit

let HOME      = NSHomeDirectory()
let ICON_SRC  = "\(HOME)/Desktop/app-icon.svg"
let LOGO_SRC  = "\(HOME)/Desktop/logo-full.svg"
let APP       = CommandLine.arguments.count > 1
                 ? CommandLine.arguments[1]
                 : "\(HOME)/Desktop/Gimme SVG.app"
let RESOURCES = "\(APP)/Contents/Resources"

// MARK: - SVG-helpers

/// Henter alt mellom <svg ...> og </svg>, og fjerner <defs>...</defs>
/// så vi kan stylee paths fritt med vår egen CSS.
func extractInnerSVG(_ svg: String) -> String {
    var s = svg
    // Drop <defs>...</defs> som inneholder cls-1 stylesheet
    s = s.replacingOccurrences(
        of: "<defs>[\\s\\S]*?</defs>",
        with: "",
        options: .regularExpression)
    // Plukk ut innmaten av rot-<svg>
    guard let openRange = s.range(of: "<svg[^>]*>", options: .regularExpression),
          let closeRange = s.range(of: "</svg>",
                                    range: openRange.upperBound..<s.endIndex)
    else { return s }
    return String(s[openRange.upperBound..<closeRange.lowerBound])
}

/// Bygger full HTML+SVG som rendres i WebView. Alle paths/shapes i .icon-laget
/// tvinges til hvit via CSS, mens bakgrunnen beholder sin gradient.
func makeIconHTML(innerSVG: String, size: Int) -> String {
    let canvas = 1024
    let pad = Double(canvas) * 0.18
    let scale = (Double(canvas) - 2 * pad) / 181.37
    let cornerRadius = 225

    return """
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="UTF-8">
    <style>
      html, body { margin: 0; padding: 0; width: \(size)px; height: \(size)px;
                   background: transparent; overflow: hidden; }
      svg { display: block; width: 100%; height: 100%; }
      .icon * { fill: #ffffff !important; stroke: #ffffff !important; }
    </style>
    </head>
    <body>
    <svg viewBox="0 0 \(canvas) \(canvas)" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient id="bg" x1="0" y1="0" x2="\(canvas)" y2="\(canvas)"
                        gradientUnits="userSpaceOnUse">
          <stop offset="0" stop-color="#7533ED"/>
          <stop offset="1" stop-color="#5C45F2"/>
        </linearGradient>
      </defs>
      <rect width="\(canvas)" height="\(canvas)" rx="\(cornerRadius)" fill="url(#bg)"/>
      <g class="icon" transform="translate(\(pad), \(pad)) scale(\(scale))">
        \(innerSVG)
      </g>
    </svg>
    </body>
    </html>
    """
}

// MARK: - WKWebView-basert renderer

final class WebRenderer: NSObject, WKNavigationDelegate {
    private let webView: WKWebView
    private let window: NSWindow
    private var completion: ((Data?) -> Void)?

    init(initialSize: Int) {
        let cfg = WKWebViewConfiguration()
        let frame = NSRect(x: 0, y: 0, width: initialSize, height: initialSize)
        webView = WKWebView(frame: frame, configuration: cfg)
        webView.setValue(false, forKey: "drawsBackground")

        // WKWebView trenger å være i et ekte vindu for å rendre.
        // Vi gjør det usynlig ved å plassere det utenfor skjermen.
        window = NSWindow(contentRect: NSRect(x: -10000, y: -10000,
                                              width: initialSize, height: initialSize),
                          styleMask: [.borderless],
                          backing: .buffered, defer: false)
        window.contentView = webView
        window.orderFront(nil)

        super.init()
        webView.navigationDelegate = self
    }

    func render(html: String, size: Int, completion: @escaping (Data?) -> Void) {
        self.completion = completion
        let frame = NSRect(x: 0, y: 0, width: size, height: size)
        webView.frame = frame
        var winFrame = window.frame
        winFrame.size = frame.size
        window.setFrame(winFrame, display: true)
        webView.loadHTMLString(html, baseURL: nil)
    }

    // Når sida er ferdig lastet, vent et lite øyeblikk og snapshot
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            let cfg = WKSnapshotConfiguration()
            cfg.rect = self.webView.bounds
            self.webView.takeSnapshot(with: cfg) { image, error in
                guard let image = image,
                      let tiff = image.tiffRepresentation,
                      let bm = NSBitmapImageRep(data: tiff) else {
                    self.completion?(nil)
                    return
                }
                let png = bm.representation(using: .png, properties: [:])
                self.completion?(png)
            }
        }
    }
}

// MARK: - Hovedflyt

let sizeMap: [(Int, String)] = [
    (16,   "icon_16x16.png"),
    (32,   "icon_16x16@2x.png"),
    (32,   "icon_32x32.png"),
    (64,   "icon_32x32@2x.png"),
    (128,  "icon_128x128.png"),
    (256,  "icon_128x128@2x.png"),
    (256,  "icon_256x256.png"),
    (512,  "icon_256x256@2x.png"),
    (512,  "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

func runAll() {
    do {
        let iconSVG = try String(contentsOfFile: ICON_SRC, encoding: .utf8)
        let logoSVG = try String(contentsOfFile: LOGO_SRC, encoding: .utf8)

        // Sørg for Resources-mappa
        try FileManager.default.createDirectory(
            atPath: RESOURCES, withIntermediateDirectories: true)

        // Skriv hvit logo: bare bytt ut style-blokk + sett fill="#fff" på root <g>
        var logoWhite = logoSVG
        logoWhite = logoWhite.replacingOccurrences(
            of: "<defs>[\\s\\S]*?</defs>",
            with: "<defs><style>* { fill: #ffffff !important; }</style></defs>",
            options: .regularExpression)
        try logoWhite.write(toFile: "\(RESOURCES)/logo.svg",
                            atomically: true, encoding: .utf8)
        print("✓ logo.svg")

        // Bygg ikon-iconset
        let iconset = "/tmp/gimme.iconset"
        try? FileManager.default.removeItem(atPath: iconset)
        try FileManager.default.createDirectory(
            atPath: iconset, withIntermediateDirectories: true)

        let inner = extractInnerSVG(iconSVG)
        let renderer = WebRenderer(initialSize: 1024)

        // Renderer ett og ett synkront via callbacks
        var index = 0
        func next() {
            guard index < sizeMap.count else {
                // Alle PNG-er klare → lag .icns
                let task = Process()
                task.launchPath = "/usr/bin/iconutil"
                task.arguments = ["-c", "icns", iconset,
                                  "-o", "\(RESOURCES)/AppIcon.icns"]
                do {
                    try task.run()
                } catch {
                    print("iconutil feilet: \(error)")
                    exit(1)
                }
                task.waitUntilExit()

                guard task.terminationStatus == 0 else {
                    print("iconutil returnerte \(task.terminationStatus)")
                    exit(1)
                }

                try? FileManager.default.removeItem(atPath: iconset)
                print("✓ AppIcon.icns")
                print("\n🎉 Resources klare i \(RESOURCES)")
                exit(0)
            }

            let (size, name) = sizeMap[index]
            let html = makeIconHTML(innerSVG: inner, size: size)
            renderer.render(html: html, size: size) { data in
                if let data = data {
                    let path = "\(iconset)/\(name)"
                    do {
                        try data.write(to: URL(fileURLWithPath: path))
                        print("  ✓ \(name) (\(size)px)")
                    } catch {
                        print("  ✗ \(name): \(error)")
                    }
                } else {
                    print("  ✗ \(name) – snapshot feilet")
                }
                index += 1
                DispatchQueue.main.async { next() }
            }
        }

        DispatchQueue.main.async { next() }
    } catch {
        print("Feil: \(error)")
        exit(1)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
DispatchQueue.main.async { runAll() }
app.run()
