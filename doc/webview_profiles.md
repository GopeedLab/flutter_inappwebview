# Persistent WebView profiles

A profile groups persistent cookies and website data across WebViews. Use a stable
UUID for each identity, and keep it when reopening a view or restarting the app.
This API is independent of Gopeed and available to any Flutter application.

```dart
final profile = WebViewProfile('12345678-1234-1234-1234-123456789abc');
await profile.prepare(); // System network route; no custom proxy required.

final view = InAppWebView(
  initialSettings: InAppWebViewSettings(profileId: profile.id),
  initialUrlRequest: URLRequest(url: WebUri('https://example.com')),
);

final cookies = await profile.cookieManager.getCookies(
  url: WebUri('https://example.com'),
);
// Equivalent: CookieManager.instance(profileId: profile.id).

// Dispose every WebView using this profile before removing it:
await profile.remove();
```

Always await `prepare` before constructing a view or using its cookies. Pass the
normalized `profile.id` to settings. `profileId` is a creation option: it cannot
switch an existing view's identity. Do not combine it with `incognito` or
`sharedCookiesEnabled`; those settings request a different storage policy.
Closing a view does not remove its data. Removal is explicit and retryable.

The existing constructors and default cookie manager retain their behavior when
`profileId` is omitted. The new setting and methods are additive Dart APIs.

## Platform support

| Platform | Persistent profiles | Optional proxy | Removal |
| --- | --- | --- | --- |
| Android | WebView `MULTI_PROFILE` support | HTTP URL, requires `PROXY_OVERRIDE`; application-wide | Clear all data using `DELETE_BROWSING_DATA` for a loaded profile, then delete its shell next startup |
| iOS | iOS 17+ | SOCKS5 URL, scoped to the profile | Clear website data and remove the named WebKit store |
| macOS | macOS 14+ | SOCKS5 URL, scoped to the profile | Clear website data and remove the named WebKit store |
| Windows / web | Not implemented by this API | Not implemented | Not implemented |

Android requires minSdk 21 and AndroidX WebKit 1.13.0 in this fork. If a loaded
Android profile cannot be fully cleared, removal reports an error and queues
removal for the next process start. It never clears another profile's data.
Callers must handle unsupported-feature and removal errors.

To use a proxy, supply `proxyUrl` to `prepare`, for example
`Uri.parse('socks5://proxy.example.com:1080')` on Apple or
`Uri.parse('http://proxy.example.com:8080')` on Android. Hostnames are unrestricted;
URL credentials are unsupported. Passing null restores the system route.
On Android this changes the route of ALL app WebViews, including default-profile
views. Do not configure competing proxies across Android profiles. Route changes
apply to new connections; existing tunnels can retain their previous route.

## Local tests

The facade package includes relative sibling overrides so tests exercise the
matching platform implementations in this checkout:

```sh
cd flutter_inappwebview
flutter pub get
flutter test test/webview_profile_test.dart
```

Overrides in a dependency's pubspec_overrides.yaml are ignored by consuming apps.
Apps using the Git fork must override all five changed packages to one commit:
`flutter_inappwebview`, `flutter_inappwebview_platform_interface`,
`flutter_inappwebview_android`, `flutter_inappwebview_ios`, and
`flutter_inappwebview_macos`.
