// Native persistent profile lifecycle.
import Foundation
import WebKit
import Network
import Flutter

final class WebViewProfiles {
    private static var proxyURLs: [String: String] = [:]
    private static var stores: [String: WKWebsiteDataStore] = [:]
    static func store(_ identifier: String) -> WKWebsiteDataStore? { stores[identifier] }

    static func prepare(arguments: NSDictionary?, result: @escaping FlutterResult) {
        guard #available(macOS 14.0, iOS 17.0, *) else {
            result(FlutterError(code: "UNAVAILABLE", message: "Persistent profiles require macOS 14 / iOS 17 or newer", details: nil))
            return
        }
        guard let identifier = arguments?["profileId"] as? String,
              let uuid = UUID(uuidString: identifier) else {
            result(FlutterError(code: "INVALID_REQUEST", message: "Invalid profile UUID", details: nil))
            return
        }
        let proxyURL = arguments?["proxyUrl"] as? String ?? ""
        if stores[identifier] != nil && proxyURLs[identifier] == proxyURL {
            result(true)
            return
        }
        let store = stores[identifier] ?? WKWebsiteDataStore(forIdentifier: uuid)
        if proxyURL.isEmpty {
            store.__proxyConfigurations = []
        } else {
            guard let url = URL(string: proxyURL), url.scheme == "socks5",
                  let host = url.host, !host.isEmpty,
                  url.user == nil, url.password == nil,
                  (1...65535).contains(url.port ?? 1080) else {
                result(FlutterError(code: "INVALID_REQUEST", message: "Expected a SOCKS5 proxy URL without credentials", details: nil))
                return
            }
            let endpoint = nw_endpoint_create_host(host, String(url.port ?? 1080))
            store.__proxyConfigurations = [nw_proxy_config_create_socksv5(endpoint)]
        }
        stores[identifier] = store
        proxyURLs[identifier] = proxyURL
        result(true)
    }
    static func remove(arguments: NSDictionary?, result: @escaping FlutterResult) {
        guard let identifier = arguments?["profileId"] as? String,
              let uuid = UUID(uuidString: identifier) else {
            result(FlutterError(code: "INVALID_REQUEST", message: "Invalid WebView profile identifier", details: nil))
            return
        }
        guard #available(macOS 14.0, iOS 17.0, *) else {
            // Named stores could not have been created on these OS versions.
            result(true)
            return
        }
        // Deleting a named store alone can leave in-process cookie caches.
        // Clear every website data type before releasing/removing the store.
        let store = stores[identifier] ?? WKWebsiteDataStore(forIdentifier: uuid)
        store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: Date.distantPast) {
            stores.removeValue(forKey: identifier)
            proxyURLs.removeValue(forKey: identifier)
            removeStore(uuid, attempts: 100, result: result)
        }
    }

    @available(macOS 14.0, iOS 17.0, *)
    private static func removeStore(_ uuid: UUID, attempts: Int, result: @escaping FlutterResult) {
        WKWebsiteDataStore.remove(forIdentifier: uuid) { error in
            if error != nil && attempts > 1 {
                // Network-process references can outlive platform-view disposal.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    removeStore(uuid, attempts: attempts - 1, result: result)
                }
                return
            }
            if let error = error {
                result(FlutterError(code: "PROFILE_REMOVE_FAILED", message: error.localizedDescription, details: nil))
            } else {
                result(true)
            }
        }
    }

}
