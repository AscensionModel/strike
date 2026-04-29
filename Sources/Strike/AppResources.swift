import AppKit
import Foundation

enum AppResources {
    static func url(forResource name: String, withExtension fileExtension: String) -> URL? {
        resourceBundleURLs()
            .compactMap { Bundle(url: $0) }
            .compactMap { $0.url(forResource: name, withExtension: fileExtension) }
            .first
    }

    static func image(named name: String) -> NSImage? {
        guard let url = url(forResource: name, withExtension: "png") else {
            return nil
        }

        return NSImage(contentsOf: url)
    }

    private static func resourceBundleURLs() -> [URL] {
        var urls: [URL] = []
        let bundleName = "Strike_Strike.bundle"

        urls.append(Bundle.main.bundleURL.appendingPathComponent(bundleName))

        if let resourceURL = Bundle.main.resourceURL {
            urls.append(resourceURL.appendingPathComponent(bundleName))
        }

        urls.append(Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent(bundleName))

        return urls
    }
}
