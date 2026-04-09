import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'pubsub_config.dart';

abstract class PubSubClient {
  Stream<Map<String, dynamic>> get messages;
  Stream<String> get connectionEvents;
  Future<void> connect(PubSubConfig config);
  Future<void> joinGroup(String group, {int? ackId});
  Future<void> publish(Map<String, Object?> message);
  Future<void> disconnect();
}

class WebSocketPubSubClient implements PubSubClient {
  WebSocket? _socket;
  final StreamController<Map<String, dynamic>> _messages =
      StreamController.broadcast();
  final StreamController<String> _connectionEvents =
      StreamController.broadcast();

  @override
  Stream<Map<String, dynamic>> get messages => _messages.stream;

  @override
  Stream<String> get connectionEvents => _connectionEvents.stream;

  @override
  Future<void> connect(PubSubConfig config) async {
    _connectionEvents.add('connecting');
    final url = config.clientAccessUrl ??
        '${config.url}/client/hubs/${config.hub}?access_token=${Uri.encodeQueryComponent(config.accessToken)}';
    _socket = await WebSocket.connect(
      url,
      protocols: const ['json.webpubsub.azure.v1'],
    );
    _connectionEvents.add('connected');
    _socket!.listen(
      (dynamic data) {
        if (data is String && data.isNotEmpty) {
          _messages.add(jsonDecode(data) as Map<String, dynamic>);
        }
      },
      onDone: () => _connectionEvents.add('closed'),
      onError: (Object error, StackTrace stackTrace) {
        _connectionEvents.add('error:$error');
      },
      cancelOnError: false,
    );
  }

  @override
  Future<void> joinGroup(String group, {int? ackId}) async {
    _socket?.add(jsonEncode({
      'type': 'joinGroup',
      'group': group,
      if (ackId != null) 'ackId': ackId,
    }));
  }

  @override
  Future<void> publish(Map<String, Object?> message) async {
    _socket?.add(jsonEncode(message));
  }

  @override
  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
    _connectionEvents.add('closed');
  }
}
