import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_android/flutter_inappwebview_android.dart';
import 'package:flutter_inappwebview_ios/flutter_inappwebview_ios.dart';
import 'package:flutter_inappwebview_macos/flutter_inappwebview_macos.dart';

class UnsupportedPlatform extends InAppWebViewPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const id = '12345678-1234-1234-1234-123456789abc';
  const channel =
      MethodChannel('com.pichillilorenzo/flutter_inappwebview_cookiemanager');
  const utility =
      MethodChannel('com.pichillilorenzo/flutter_inappwebview_platformutil');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(utility, (call) async => '17.0');
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'getCookies' || call.method == 'getAllCookies') {
        return [
          {
            'name': 'session',
            'value': 'saved',
            'domain': 'example.com',
            'path': '/',
            'isHttpOnly': true
          }
        ];
      }
      return true;
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(utility, null);
  });

  test('profile is a typed, serializable initialization setting', () {
    final settings = InAppWebViewSettings(profileId: id);
    expect(settings.toMap()['profileId'], id);
    expect(InAppWebViewSettings.fromMap(settings.toMap())!.profileId, id);
    expect(InAppWebViewSettings().profileId, isNull);
  });

  for (final platform in <String, InAppWebViewPlatform>{
    'android': AndroidInAppWebViewPlatform(),
    'ios': IOSInAppWebViewPlatform(),
    'macos': MacOSInAppWebViewPlatform(),
  }.entries) {
    test('${platform.key}: profile lifecycle and cookies stay scoped',
        () async {
      InAppWebViewPlatform.instance = platform.value;
      final profile = WebViewProfile(id);
      await profile.prepare();
      expect(calls.last.arguments, {'profileId': id, 'proxyUrl': null});
      final proxy = Uri.parse(platform.key == 'android'
          ? 'http://proxy.example.com:8080'
          : 'socks5://proxy.example.com:1080');
      await profile.prepare(proxyUrl: proxy);
      expect(calls.last.arguments['proxyUrl'], proxy.toString());
      final cookies = profile.cookieManager;
      await cookies.setCookie(
          url: WebUri('https://example.com'),
          name: 'session',
          value: 'saved',
          isHttpOnly: true);
      expect(
          (await cookies.getCookies(url: WebUri('https://example.com')))
              .single
              .value,
          'saved');
      await cookies.deleteCookie(
          url: WebUri('https://example.com'), name: 'session');
      await cookies.deleteAllCookies();
      await profile.remove();
      expect(calls.map((c) => c.method), [
        'prepareProfile',
        'prepareProfile',
        'setCookie',
        'getCookies',
        'deleteCookie',
        'deleteAllCookies',
        'removeProfile'
      ]);
      expect(calls.every((c) => c.arguments['profileId'] == id), isTrue);
      final defaults = CookieManager.fromPlatformCreationParams(
          const PlatformCookieManagerCreationParams());
      await defaults.deleteAllCookies();
      expect(calls.last.arguments.containsKey('profileId'), isFalse);
    });
    test('${platform.key}: profile errors propagate', () async {
      InAppWebViewPlatform.instance = platform.value;
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'UNAVAILABLE', message: 'Not supported');
      });
      await expectLater(
          WebViewProfile(id).prepare(), throwsA(isA<PlatformException>()));
    });
  }
  test('invalid identifiers and unsupported platforms fail explicitly', () {
    InAppWebViewPlatform.instance = UnsupportedPlatform();
    expect(() => WebViewProfile(''), throwsArgumentError);
    expect(() => WebViewProfile(id), throwsUnsupportedError);
  });
}
