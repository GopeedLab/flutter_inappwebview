import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'inappwebview_platform.dart';

/// Platform implementation of a persistent browser profile.
abstract class PlatformWebViewProfile extends PlatformInterface {
  factory PlatformWebViewProfile(String id) {
    if (!RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
        .hasMatch(id)) {
      throw ArgumentError.value(id, 'id', 'Expected a UUID');
    }
    final platform = InAppWebViewPlatform.instance;
    if (platform == null) throw StateError('No WebView platform registered');
    final result = platform.createPlatformWebViewProfile(id.toLowerCase());
    PlatformInterface.verify(result, _token);
    return result;
  }

  PlatformWebViewProfile.implementation(this.id) : super(token: _token);
  static final Object _token = Object();
  final String id;

  Future<void> prepare({Uri? proxyUrl}) => throw UnimplementedError('prepare');
  Future<void> remove() => throw UnimplementedError('remove');
}
