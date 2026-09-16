# Gopeed native WebView host bridge

Maintenance branch: `codex/gopeed-profiles`. Based on upstream `v6.1.5`
(`f67ae1f34868c7660c16a2473f53a7a7bfb6f784`), which contains:

- flutter_inappwebview_macos 1.1.2
- flutter_inappwebview_ios 1.1.2
- flutter_inappwebview_android 1.1.3

Upstream history and licenses are preserved. `master` is reserved for upstream;
Gopeed patches live on the maintenance branch. Gopeed pins the same immutable Git
commit for all three platform packages through `dependency_overrides`.

Local native changes are limited to:

- `GopeedProfiles`: remove profiles on uninstall and prepare a persistent profile and apply the internal loopback
  proxy before creating a WebView. Apple uses SOCKS5 to cover HTTP as well as HTTPS;
  Android uses the application-wide HTTP proxy override completion callback.
- `InAppWebViewSettings` and `InAppWebView`: read the host-only `gopeedProfileId`
  setting and attach the profile before navigation.
- `MyCookieManager`: route cookie operations to the requested profile, capturing
  the store per operation so asynchronous calls cannot cross profiles.
- macOS `InAppWebView`: resign input focus before disposing a view so AppKit
  cannot retain its profile through the responder chain after closing the page.

`lib/app/rpc/webview_profile.dart` uses the existing plugin method channel and
serializes these internal settings. No extension JavaScript API is added.

Apple requires macOS 14 / iOS 17 for named persistent stores and proxy settings.
Android requires `MULTI_PROFILE` and `PROXY_OVERRIDE`; unsupported runtimes return
an explicit unavailable error rather than opening a shared, unproxied browser.

## Updating upstream

1. Fetch the upstream repository and tags (`git fetch upstream --tags`).
2. Merge a compatible upstream release into `codex/gopeed-profiles`, resolving
   native changes while retaining the host-only profile and proxy behavior.
3. Review `git diff v6.1.5..HEAD` (use the new baseline after an upgrade). Do not
   replace entire package directories with published archives.
4. Run the shared Gopeed provider integration tests against the normal, visible
   Flutter app on macOS, and the existing Android/iOS build jobs. The input-focus
   cleanup regression requires a visible app; hidden-only testing is insufficient.
5. Update all three Git refs in Gopeed's `pubspec.yaml` to the verified commit,
   run `flutter pub get`, and commit the updated lockfile.

The Flutter-facing public APIs remain upstream APIs. The profile settings and
method-channel operations are private host implementation details.

Android uses AndroidX WebKit 1.13.0 for profile-scoped full browsing-data deletion.
Loaded profile shells are queued durably for deletion before WebViews initialize
at the next process start. No global cookie/cache clearing is used for uninstall.
