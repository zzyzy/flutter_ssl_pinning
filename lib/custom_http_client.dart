import 'dart:convert';
import 'dart:io';

import 'package:flutter_ssl_pinning/invalid_ssl_certificate_exception.dart';

typedef ServerCertificateCustomValidationCallback = bool Function(
    List<X509Certificate> chain, String host, int port);

/// Customized HttpClient that implements ServerCertificateCustomValidationCallback
/// from C#'s HttpClient for certificate pinning usage.
///
class CustomHttpClient implements HttpClient {
  CustomHttpClient() {
    // We need to use an empty SecurityContext so that
    // badCertificateCallback can be triggered
    //
    _httpClient = HttpClient(context: SecurityContext());
    _httpClient.badCertificateCallback = _badCertificateCallback;
  }

  ServerCertificateCustomValidationCallback?
      serverCertificateCustomValidationCallback;

  late final HttpClient _httpClient;
  final Map<String, _BadCertificateResult> _badCertificateMap = {};

  @override
  bool get autoUncompress => _httpClient.autoUncompress;

  @override
  set autoUncompress(bool value) => _httpClient.autoUncompress = value;

  @override
  Duration? get connectionTimeout => _httpClient.connectionTimeout;

  @override
  set connectionTimeout(Duration? value) =>
      _httpClient.connectionTimeout = value;

  @override
  Duration get idleTimeout => _httpClient.idleTimeout;

  @override
  set idleTimeout(Duration value) => _httpClient.idleTimeout = value;

  @override
  int? get maxConnectionsPerHost => _httpClient.maxConnectionsPerHost;

  @override
  set maxConnectionsPerHost(int? value) =>
      _httpClient.maxConnectionsPerHost = value;

  @override
  String? get userAgent => _httpClient.userAgent;

  @override
  set userAgent(String? value) => _httpClient.userAgent = value;

  @override
  void addCredentials(
      Uri url, String realm, HttpClientCredentials credentials) {
    _httpClient.addCredentials(url, realm, credentials);
  }

  @override
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {
    _httpClient.addProxyCredentials(host, port, realm, credentials);
  }

  @override
  set authenticate(
          Future<bool> Function(Uri url, String scheme, String? realm)? f) =>
      _httpClient.authenticate = f;

  @override
  set authenticateProxy(
          Future<bool> Function(
                  String host, int port, String scheme, String? realm)?
              f) =>
      _httpClient.authenticateProxy = f;

  /// This method will do nothing. Use
  /// [serverCertificateCustomValidationCallback] instead.
  @override
  set badCertificateCallback(
      bool Function(X509Certificate cert, String host, int port)? callback) {
    // Do nothing
  }

  @override
  void close({bool force = false}) {
    _httpClient.close(force: force);
  }

  @override
  set connectionFactory(
          Future<ConnectionTask<Socket>> Function(
                  Uri url, String? proxyHost, int? proxyPort)?
              f) =>
      _httpClient.connectionFactory = f;

  @override
  set findProxy(String Function(Uri url)? f) => _httpClient.findProxy = f;

  @override
  set keyLog(Function(String line)? callback) => _httpClient.keyLog = callback;

  @override
  Future<HttpClientRequest> open(
      String method, String host, int port, String path) async {
    //  Wrap the request with our own request wrapper
    final req = await _httpClient.open(method, host, port, path);
    final creq = CustomHttpClientRequest(this, req);
    return creq;
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    //  Wrap the request with our own request wrapper
    final req = await _httpClient.openUrl(method, url);
    final creq = CustomHttpClientRequest(this, req);
    return creq;
  }

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      open("delete", host, port, path);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl("delete", url);

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      open("get", host, port, path);

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl("get", url);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      open("head", host, port, path);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl("head", url);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      open("patch", host, port, path);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl("patch", url);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      open("post", host, port, path);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl("post", url);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      open("put", host, port, path);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl("put", url);

  bool _badCertificateCallback(X509Certificate cert, String host, int port) {
    // If there's no callback registered, then return false (default behavior)
    if (serverCertificateCustomValidationCallback == null) {
      return false;
    }

    // Store the certificate, host and port number
    _badCertificateMap['$host:$port'] = _BadCertificateResult(cert, host, port);
    return true;
  }
}

class _BadCertificateResult {
  _BadCertificateResult(this.cert, this.host, this.port);

  X509Certificate cert;
  String host;
  int port;
}

class CustomHttpClientRequest extends HttpClientRequest {
  CustomHttpClientRequest(this._httpClient, this._req);

  final CustomHttpClient _httpClient;
  final HttpClientRequest _req;

  @override
  Encoding get encoding => _req.encoding;

  @override
  set encoding(Encoding value) => _req.encoding = value;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {
    _req.abort(exception, stackTrace);
  }

  @override
  void add(List<int> data) {
    _req.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _req.addError(error, stackTrace);
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    return _req.addStream(stream);
  }

  @override
  Future<HttpClientResponse> close() async {
    final res = await _req.close();

    final isSecure = uri.isScheme('https');

    // Certificate pinning only applies to HTTPS traffic
    if (isSecure) {
      final host = uri.host;
      final port = uri.port;
      final key = '$host:$port';

      if (_httpClient.serverCertificateCustomValidationCallback != null) {
        final chain = <X509Certificate>[];

        // Add the leaf cert
        if (res.certificate != null) {
          chain.add(res.certificate!);
        }

        // Add the intermediate or root cert (we can't control this)
        if (_httpClient._badCertificateMap.containsKey(key)) {
          chain.add(_httpClient._badCertificateMap[key]!.cert);
        }

        // Execute the callback
        final isValid = _httpClient.serverCertificateCustomValidationCallback!(
            chain, host, port);
        if (!isValid) {
          throw InvalidSslCertificateException(
              'Failed certificate verification.');
        }
      }
    }

    return res;
  }

  @override
  HttpConnectionInfo? get connectionInfo => _req.connectionInfo;

  @override
  List<Cookie> get cookies => _req.cookies;

  @override
  Future<HttpClientResponse> get done => _req.done;

  @override
  Future flush() {
    return _req.flush();
  }

  @override
  HttpHeaders get headers => _req.headers;

  @override
  String get method => _req.method;

  @override
  Uri get uri => _req.uri;

  @override
  void write(Object? object) {
    _req.write(object);
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    _req.writeAll(objects, separator);
  }

  @override
  void writeCharCode(int charCode) {
    _req.writeCharCode(charCode);
  }

  @override
  void writeln([Object? object = ""]) {
    _req.writeln(object);
  }
}
