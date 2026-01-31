import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mise_app/screens/onboarding_screen.dart';

// Minimal manual HttpClient mock to handle NetworkImage in tests without external dependencies.
class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> get(String host, int port, String path) => throw UnimplementedError();
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> post(String host, int port, String path) => throw UnimplementedError();
  @override
  Future<HttpClientRequest> postUrl(Uri url) => throw UnimplementedError();
  @override
  Future<HttpClientRequest> put(String host, int port, String path) => throw UnimplementedError();
  @override
  Future<HttpClientRequest> putUrl(Uri url) => throw UnimplementedError();
  @override
  Future<HttpClientRequest> delete(String host, int port, String path) => throw UnimplementedError();
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => throw UnimplementedError();
  @override
  Future<HttpClientRequest> patch(String host, int port, String path) => throw UnimplementedError();
  @override
  Future<HttpClientRequest> patchUrl(Uri url) => throw UnimplementedError();
  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) => throw UnimplementedError();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) => throw UnimplementedError();
  @override
  Future<HttpClientRequest> head(String host, int port, String path) => throw UnimplementedError();
  @override
  Future<HttpClientRequest> headUrl(Uri url) => throw UnimplementedError();
  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}
  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String realm)? f) {}
  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String realm)? f) {}
  @override
  set findProxy(String Function(Uri url)? f) {}
  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) {}
  @override
  void close({bool force = false}) {}
  @override
  set connectionFactory(Future<ConnectionTask<Socket>> Function(Uri url, String? proxyHost, int? proxyPort)? f) {}
  @override
  set keyLog(void Function(String line)? f) {}
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = true;
  @override
  HttpHeaders get headers => _MockHttpHeaders();
  @override
  Future<HttpClientResponse> get done => throw UnimplementedError();
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  void add(List<int> data) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future<void> addStream(Stream<List<int>> stream) async {}
  @override
  void write(Object? obj) {}
  @override
  void writeAll(Iterable<Object?> objects, [String separator = ""]) {}
  @override
  void writeCharCode(int charCode) {}
  @override
  void writeln([Object? obj = ""]) {}
  @override
  set bufferOutput(bool _bufferOutput) {}
  @override
  bool get bufferOutput => true;
  @override
  int get contentLength => 0;
  @override
  set contentLength(int _contentLength) {}
  @override
  Encoding get encoding => utf8;
  @override
  set encoding(Encoding _encoding) {}
  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
  @override
  HttpConnectionInfo? get connectionInfo => throw UnimplementedError();
  @override
  List<Cookie> get cookies => throw UnimplementedError();
  @override
  String get method => throw UnimplementedError();
  @override
  Uri get uri => throw UnimplementedError();
  @override
  Future<void> flush() async {}
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  HttpHeaders get headers => _MockHttpHeaders();
  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
  @override
  Future<Socket> detachSocket() => throw UnimplementedError();
  @override
  List<Cookie> get cookies => [];
  @override
  bool get isRedirect => false;
  @override
  String get reasonPhrase => "OK";
  @override
  List<RedirectInfo> get redirects => [];
  @override
  Future<HttpClientResponse> redirect([String? method, Uri? url, bool? followRedirects]) => throw UnimplementedError();
  @override
  bool get persistentConnection => true;
  @override
  HttpConnectionInfo? get connectionInfo => throw UnimplementedError();
  @override
  X509Certificate? get certificate => null;
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final List<int> _transparentImage = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
];

void main() {
  setUpAll(() => HttpOverrides.global = TestHttpOverrides());

  testWidgets('Onboarding screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    expect(find.text('Healthy Daily Meals'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Save Your Time'), findsOneWidget);
  });
}
