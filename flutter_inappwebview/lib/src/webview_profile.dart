import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'cookie_manager.dart';

/// A named persistent browser profile identified by a UUID.
///
/// Call [prepare] before creating WebViews with InAppWebViewSettings.profileId.
/// Cookies and website storage are shared by views using the same ID and survive
/// closing those views. Different IDs use separate website data stores.
/// Supported on Android with MULTI_PROFILE, iOS 17+, and macOS 14+.
class WebViewProfile {
  WebViewProfile(String id) : platform = PlatformWebViewProfile(id);
  WebViewProfile.fromPlatform(this.platform);
  final PlatformWebViewProfile platform;
  String get id => platform.id;
  CookieManager get cookieManager => CookieManager.instance(profileId: id);

  /// Creates or opens this profile before any WebView navigation.
  ///
  /// Null [proxyUrl] uses the system route. Apple supports SOCKS5 URLs; Android
  /// supports HTTP proxy URLs and applies the override to ALL app WebViews.
  /// Android requires PROXY_OVERRIDE when a proxy is requested. Authentication
  /// in proxy URLs is not supported. Changing the route affects new connections;
  /// existing tunnels may retain their route. Unsupported features throw.
  Future<void> prepare({Uri? proxyUrl}) => platform.prepare(proxyUrl: proxyUrl);

  /// Deletes this profile's cookies and all website data. Close its WebViews first.
  /// On Android, loaded profiles are cleared and queued for deletion at the next
  /// application start. If full clearing is unsupported, this fails until restart.
  /// Retrying removal is safe. Ordinary close and application updates do not call it.
  Future<void> remove() => platform.remove();
}
