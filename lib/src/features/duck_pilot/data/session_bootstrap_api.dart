import 'dart:convert';
import 'dart:io';

import 'package:rubberduck_flutter/src/core/models/session_join_request.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/data/pubsub_config.dart';

class SessionBootstrapRequest {
  const SessionBootstrapRequest({
    required this.playerName,
    required this.sessionCode,
    required this.deviceId,
  });

  factory SessionBootstrapRequest.fromJoinRequest(SessionJoinRequest request) {
    return SessionBootstrapRequest(
      playerName: request.playerName,
      sessionCode: request.sessionCode,
      deviceId: request.deviceId,
    );
  }

  final String playerName;
  final String sessionCode;
  final String deviceId;

  Map<String, Object?> toJson() {
    return {
      'playerName': playerName,
      'sessionCode': sessionCode,
      'deviceId': deviceId,
    };
  }
}

abstract class SessionBootstrapApi {
  Future<PubSubConfig> createConnection(SessionBootstrapRequest request);
}

class DirectClientAccessBootstrapApi implements SessionBootstrapApi {
  DirectClientAccessBootstrapApi({
    required this.clientAccessUrl,
  });

  final String clientAccessUrl;

  @override
  Future<PubSubConfig> createConnection(SessionBootstrapRequest request) async {
    final uri = Uri.parse(clientAccessUrl);
    final segments = uri.pathSegments;
    final hubIndex = segments.indexOf('hubs');
    final hub = hubIndex >= 0 && hubIndex + 1 < segments.length
        ? segments[hubIndex + 1]
        : 'rubberduck';

    return PubSubConfig(
      url: '${uri.scheme}://${uri.host}',
      accessToken: uri.queryParameters['access_token'] ?? '',
      hub: hub,
      group: request.sessionCode,
      userId: request.playerName,
      clientAccessUrl: clientAccessUrl,
    );
  }
}

class BackendSessionBootstrapApi implements SessionBootstrapApi {
  BackendSessionBootstrapApi({
    required this.endpoint,
    HttpClient? httpClient,
  }) : _httpClient = httpClient ?? HttpClient();

  final Uri endpoint;
  final HttpClient _httpClient;

  @override
  Future<PubSubConfig> createConnection(SessionBootstrapRequest request) async {
    final httpRequest = await _httpClient.postUrl(endpoint);
    httpRequest.headers.contentType = ContentType.json;
    httpRequest.write(jsonEncode(request.toJson()));

    final response = await httpRequest.close();
    final body = await utf8.decoder.bind(response).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('bootstrap failed: ${response.statusCode}');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    return PubSubConfig(
      url: json['url'] as String,
      accessToken: json['accessToken'] as String,
      hub: json['hub'] as String,
      group: json['group'] as String,
      userId: json['userId'] as String,
    );
  }
}
