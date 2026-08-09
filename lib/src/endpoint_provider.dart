import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'provider.dart';

enum EndpointRequestMethod { get, post, put, patch }

class EndpointRequestContext {
  final String appId;
  final AppPlatform platform;
  final Uri endpoint;
  final EndpointRequestMethod method;

  const EndpointRequestContext({
    required this.appId,
    required this.platform,
    required this.endpoint,
    required this.method,
  });
}

typedef EndpointPayloadBuilder =
    Map<String, dynamic> Function(String appId, AppPlatform platform);
typedef EndpointRuleBuilder =
    VersionRule Function(
      Map<String, dynamic> json,
      EndpointRequestContext context,
    );

class EndpointVersionRuleProvider implements VersionRuleProvider {
  final Uri endpoint;
  final EndpointRequestMethod method;
  final Map<String, String> headers;
  final Duration timeout;
  final http.Client _client;
  final bool _ownsClient;
  final EndpointPayloadBuilder payloadBuilder;
  final EndpointRuleBuilder ruleBuilder;

  EndpointVersionRuleProvider({
    required this.endpoint,
    this.method = EndpointRequestMethod.get,
    this.headers = const {},
    this.timeout = const Duration(seconds: 15),
    http.Client? client,
    EndpointPayloadBuilder? payloadBuilder,
    EndpointRuleBuilder? ruleBuilder,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       payloadBuilder = payloadBuilder ?? _defaultPayloadBuilder,
       ruleBuilder = ruleBuilder ?? _defaultRuleBuilder;

  @override
  Future<VersionRule> fetchRule({
    required String appId,
    required AppPlatform platform,
  }) async {
    final payload = payloadBuilder(appId, platform);
    final context = EndpointRequestContext(
      appId: appId,
      platform: platform,
      endpoint: endpoint,
      method: method,
    );

    final response = await _sendRequest(payload).timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EndpointVersionRuleException(
        'Endpoint returned HTTP ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const EndpointVersionRuleException(
        'Endpoint response must be a JSON object.',
      );
    }

    return ruleBuilder(decoded, context);
  }

  Future<http.Response> _sendRequest(Map<String, dynamic> payload) {
    final requestHeaders = <String, String>{
      'accept': 'application/json',
      ...headers,
    };

    switch (method) {
      case EndpointRequestMethod.get:
        final uri = endpoint.replace(
          queryParameters: {
            ...endpoint.queryParameters,
            ...payload.map(
              (key, value) => MapEntry(key, value?.toString() ?? ''),
            ),
          },
        );
        return _client.get(uri, headers: requestHeaders);
      case EndpointRequestMethod.post:
        return _sendJsonWithBody(
          (uri, body, headers) =>
              _client.post(uri, body: body, headers: headers),
          payload,
          requestHeaders,
        );
      case EndpointRequestMethod.put:
        return _sendJsonWithBody(
          (uri, body, headers) =>
              _client.put(uri, body: body, headers: headers),
          payload,
          requestHeaders,
        );
      case EndpointRequestMethod.patch:
        return _sendJsonWithBody(
          (uri, body, headers) =>
              _client.patch(uri, body: body, headers: headers),
          payload,
          requestHeaders,
        );
    }
  }

  Future<http.Response> _sendJsonWithBody(
    Future<http.Response> Function(
      Uri uri,
      String body,
      Map<String, String> headers,
    )
    sender,
    Map<String, dynamic> payload,
    Map<String, String> requestHeaders,
  ) {
    return sender(endpoint, jsonEncode(payload), {
      'content-type': 'application/json',
      ...requestHeaders,
    });
  }

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  static Map<String, dynamic> _defaultPayloadBuilder(
    String appId,
    AppPlatform platform,
  ) {
    return {'appId': appId, 'platform': platform.value};
  }

  static VersionRule _defaultRuleBuilder(
    Map<String, dynamic> json,
    EndpointRequestContext context,
  ) {
    try {
      return VersionRule.fromJson(json);
    } on Object catch (error) {
      throw EndpointVersionRuleException(
        'Failed to parse version rule from endpoint response: $error',
      );
    }
  }
}

class EndpointVersionRuleException implements Exception {
  final String message;

  const EndpointVersionRuleException(this.message);

  @override
  String toString() => 'EndpointVersionRuleException: $message';
}
