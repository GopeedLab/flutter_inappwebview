import 'package:flutter/services.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';

/// Android implementation of persistent browser profiles.
class AndroidWebViewProfile extends PlatformWebViewProfile {
  AndroidWebViewProfile(String id) : super.implementation(id);
  static const _channel = MethodChannel(
    'com.pichillilorenzo/flutter_inappwebview_cookiemanager',
  );
  @override
  Future<void> prepare({Uri? proxyUrl}) async {
    await _channel.invokeMethod('prepareProfile', {
      'profileId': id,
      'proxyUrl': proxyUrl?.toString(),
    });
  }

  @override
  Future<void> remove() async {
    await _channel.invokeMethod('removeProfile', {'profileId': id});
  }
}
