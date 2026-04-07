import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rubberduck_flutter/core/models/control_vector.dart';
import 'package:rubberduck_flutter/features/controller/application/controller_view_model.dart';
import 'package:rubberduck_flutter/infrastructure/pubsub/pubsub_client.dart';
import 'package:rubberduck_flutter/infrastructure/pubsub/pubsub_config.dart';
import 'package:rubberduck_flutter/infrastructure/pubsub/session_bootstrap_api.dart';

void main() {
  test('successful realtime join connects and marks controller as joined', () async {
    final viewModel = ControllerViewModel(
      bootstrapApi: _FakeBootstrapApi.success(),
      pubSubClient: _FakePubSubClient(),
      playerNameGenerator: () => 'duck-4821',
    );

    final joined = await viewModel.submitJoinRealtime();

    expect(joined, isTrue);
    expect(viewModel.state.isJoined, isTrue);
    expect(viewModel.state.connectionLabel, '실시간 연결');
    expect(viewModel.state.flagHolderLabel, '대기');
    expect(viewModel.state.sessionCode, 'rubberduck-room1');
    expect(viewModel.latestQueuedCommand, isNull);
  });

  test('publishes session join to pubsub after connecting', () async {
    final client = _FakePubSubClient();
    final logs = <String>[];
    final viewModel = ControllerViewModel(
      bootstrapApi: _FakeBootstrapApi.success(),
      pubSubClient: client,
      playerNameGenerator: () => 'duck-4821',
      logger: logs.add,
    );

    final joined = await viewModel.submitJoinRealtime();

    expect(joined, isTrue);
    expect(client.publishedMessages, isNotEmpty);
    expect(client.publishedMessages.first['type'], 'sendToGroup');
    expect(client.publishedMessages.first['group'], 'rubberduck-room1');

    final joinPayload =
        client.publishedMessages.first['data']! as Map<String, Object?>;
    expect(joinPayload['type'], 'join');
    expect(joinPayload['playerId'], 'duck-4821');
    expect(joinPayload['sessionCode'], 'rubberduck-room1');
    expect(logs.any((log) => log.contains('pubsub.send')), isTrue);
    expect(logs.any((log) => log.contains('session.join')), isTrue);
    expect(logs.any((log) => log.contains('pubsub.connection')), isTrue);
  });

  test('failed bootstrap leaves controller disconnected with an error', () async {
    final viewModel = ControllerViewModel(
      bootstrapApi: _FakeBootstrapApi.failure(),
      pubSubClient: _FakePubSubClient(),
      playerNameGenerator: () => 'duck-4821',
    );

    final joined = await viewModel.submitJoinRealtime();

    expect(joined, isFalse);
    expect(viewModel.state.isJoined, isFalse);
    expect(viewModel.state.connectionLabel, '연결 실패');
    expect(viewModel.state.errorMessage, isNotEmpty);
    expect(viewModel.state.showReconnectAction, isTrue);
  });

  test('publishes move and stop frames to the joined session group', () async {
    final client = _FakePubSubClient();
    final logs = <String>[];
    final viewModel = ControllerViewModel(
      bootstrapApi: _FakeBootstrapApi.success(),
      pubSubClient: client,
      playerNameGenerator: () => 'duck-4821',
      logger: logs.add,
    );

    final joined = await viewModel.submitJoinRealtime();
    expect(joined, isTrue);

    viewModel.onHoldStarted();
    viewModel.onGyroVectorChanged(
      const ControlVector(
        x: 0.7,
        y: 0.8,
        active: true,
      ),
    );

    expect(client.publishedMessages, isNotEmpty);
    expect(client.publishedMessages.last['type'], 'sendToGroup');
    expect(client.publishedMessages.last['group'], 'rubberduck-room1');

    final moveData =
        client.publishedMessages.last['data']! as Map<String, Object?>;
    expect(moveData, {
      'type': 'controller.move',
      'playerId': 'duck-1',
      'sessionCode': 'rubberduck-room1',
      'direction': 'upRight',
    });

    viewModel.onStopPressed();

    final stopData =
        client.publishedMessages.last['data']! as Map<String, Object?>;
    expect(stopData, {
      'type': 'controller.stop',
      'playerId': 'duck-1',
      'sessionCode': 'rubberduck-room1',
      'direction': 'idle',
    });
    expect(logs.any((log) => log.contains('pubsub.send')), isTrue);
    expect(logs.any((log) => log.contains('controller.move')), isTrue);
    expect(logs.any((log) => log.contains('controller.stop')), isTrue);
  });

  test('applies inbound session and flag updates from pubsub messages', () async {
    final client = _FakePubSubClient();
    final logs = <String>[];
    final viewModel = ControllerViewModel(
      bootstrapApi: _FakeBootstrapApi.success(),
      pubSubClient: client,
      playerNameGenerator: () => 'duck-4821',
      logger: logs.add,
    );

    final joined = await viewModel.submitJoinRealtime();
    expect(joined, isTrue);

    client.emit({
      'type': 'message',
      'event': 'session.state',
      'data': {
        'connectionLabel': '실시간 연결',
        'countdown': '00:05',
      },
    });

    client.emit({
      'type': 'message',
      'event': 'flag.state',
      'data': {
        'holderLabel': 'Duck 3',
      },
    });

    await Future<void>.delayed(Duration.zero);

    expect(viewModel.state.countdownLabel, '00:05');
    expect(viewModel.state.flagHolderLabel, 'Duck 3');
    expect(logs.any((log) => log.contains('pubsub.recv')), isTrue);
    expect(logs.any((log) => log.contains('flag.state')), isTrue);
  });

  test('applies inbound player assignment to joined state', () async {
    final client = _FakePubSubClient();
    final viewModel = ControllerViewModel(
      bootstrapApi: _FakeBootstrapApi.success(),
      pubSubClient: client,
      playerNameGenerator: () => 'duck-4821',
    );

    final joined = await viewModel.submitJoinRealtime();
    expect(joined, isTrue);

    client.emit({
      'type': 'message',
      'event': 'player.assignment',
      'data': {
        'playerId': 'duck-3',
      },
    });

    await Future<void>.delayed(Duration.zero);

    expect(viewModel.state.playerId, 'duck-3');
    expect(viewModel.state.connectionLabel, '실시간 연결');
  });

  test('logs ack and connection lifecycle updates from pubsub', () async {
    final client = _FakePubSubClient();
    final logs = <String>[];
    final viewModel = ControllerViewModel(
      bootstrapApi: _FakeBootstrapApi.success(),
      pubSubClient: client,
      playerNameGenerator: () => 'duck-4821',
      logger: logs.add,
    );

    final joined = await viewModel.submitJoinRealtime();
    expect(joined, isTrue);

    client.emitConnection('closed');
    client.emit({
      'type': 'ack',
      'ackId': 9,
      'success': true,
    });

    await Future<void>.delayed(Duration.zero);

    expect(logs.any((log) => log.contains('pubsub.connection') && log.contains('connected')), isTrue);
    expect(logs.any((log) => log.contains('pubsub.connection') && log.contains('closed')), isTrue);
    expect(logs.any((log) => log.contains('pubsub.ack') && log.contains('ackId=9')), isTrue);
    expect(viewModel.state.showReconnectAction, isTrue);
  });
}

class _FakeBootstrapApi implements SessionBootstrapApi {
  _FakeBootstrapApi.success() : _shouldFail = false;
  _FakeBootstrapApi.failure() : _shouldFail = true;

  final bool _shouldFail;

  @override
  Future<PubSubConfig> createConnection(SessionBootstrapRequest request) async {
    if (_shouldFail) {
      throw Exception('bootstrap failed');
    }

    return const PubSubConfig(
      url: 'wss://example.test/client',
      accessToken: 'token',
      hub: 'rubberduck',
      group: 'rubberduck-room1',
      userId: 'duck-1',
    );
  }
}

class _FakePubSubClient implements PubSubClient {
  bool connected = false;
  String? joinedGroup;
  final List<Map<String, Object?>> publishedMessages = [];

  @override
  Future<void> connect(PubSubConfig config) async {
    connected = true;
    _connectionController.add('connected');
  }

  @override
  Stream<Map<String, dynamic>> get messages => _controller.stream;
  @override
  Stream<String> get connectionEvents => _connectionController.stream;

  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<String>.broadcast();

  @override
  Future<void> joinGroup(String group, {int? ackId}) async {
    joinedGroup = group;
  }

  @override
  Future<void> disconnect() async {
    connected = false;
    _connectionController.add('closed');
  }

  @override
  Future<void> publish(Map<String, Object?> message) async {
    publishedMessages.add(message);
  }

  void emit(Map<String, dynamic> message) {
    _controller.add(message);
  }

  void emitConnection(String event) {
    _connectionController.add(event);
  }
}
