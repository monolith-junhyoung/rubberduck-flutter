import 'package:flutter_test/flutter_test.dart';
import 'package:rubberduck_flutter/src/core/models/control_vector.dart';
import 'package:rubberduck_flutter/src/core/models/movement_command.dart';
import 'package:rubberduck_flutter/src/core/models/session_join_request.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/data/pubsub_message_codec.dart';

void main() {
  test('encodes session join as a sendToGroup frame', () {
    final frame = PubSubMessageCodec.encodeJoin(
      const SessionJoinRequest(
        playerName: 'duck-4821',
        sessionCode: 'rubberduck-room1',
        deviceId: 'local-device',
      ),
      ackId: 1,
    );

    expect(frame['type'], 'sendToGroup');
    expect(frame['group'], 'rubberduck-room1');
    expect(frame['ackId'], 1);
    expect(frame['dataType'], 'json');
    expect(frame['data'], {
      'type': 'join',
      'playerId': 'duck-4821',
      'sessionCode': 'rubberduck-room1',
    });
  });

  test('encodes controller move frames as sendToGroup json payloads', () {
    final frame = PubSubMessageCodec.encodeMove(
      MovementCommand(
        playerId: 'duck-1',
        sessionCode: 'rubberduck-room1',
        vector: const ControlVector(x: 0.4, y: 0.8, active: true),
        direction: MovementDirection.upRight,
        active: true,
        source: 'gyro',
        sentAt: DateTime(2026, 4, 7, 18, 30),
      ),
      ackId: 2,
    );

    expect(frame['type'], 'sendToGroup');
    expect(frame['group'], 'rubberduck-room1');
    expect(frame['ackId'], 2);
    expect(frame['data'], {
      'type': 'controller.move',
      'playerId': 'duck-1',
      'sessionCode': 'rubberduck-room1',
      'direction': 'upRight',
    });
  });

  test('encodes all gameplay directions as simple direction strings', () {
    for (final direction in MovementDirection.values.where(
      (value) => value != MovementDirection.idle,
    )) {
      final frame = PubSubMessageCodec.encodeMove(
        MovementCommand(
          playerId: 'duck-1',
          sessionCode: 'rubberduck-room1',
          vector: const ControlVector(x: 0.4, y: 0.8, active: true),
          direction: direction,
          active: true,
          source: 'gyro',
          sentAt: DateTime(2026, 4, 7, 18, 30),
        ),
        ackId: 10,
      );

      expect(
        (frame['data'] as Map<String, Object?>)['direction'],
        direction.name,
      );
    }
  });

  test('encodes controller stop as idle direction payload', () {
    final frame = PubSubMessageCodec.encodeStop(
      MovementCommand(
        playerId: 'duck-1',
        sessionCode: 'rubberduck-room1',
        vector: const ControlVector(x: 0, y: 0, active: false),
        direction: MovementDirection.idle,
        active: false,
        source: 'button',
        sentAt: DateTime(2026, 4, 7, 18, 30),
      ),
      'stop',
      ackId: 3,
    );

    expect(frame['type'], 'sendToGroup');
    expect(frame['group'], 'rubberduck-room1');
    expect(frame['ackId'], 3);
    expect(frame['data'], {
      'type': 'controller.stop',
      'playerId': 'duck-1',
      'sessionCode': 'rubberduck-room1',
      'direction': 'idle',
    });
  });

  test('decodes session state messages into a typed event', () {
    final decoded = PubSubMessageCodec.decodeInbound({
      'type': 'message',
      'event': 'session.state',
      'data': {
        'connectionLabel': '실시간 연결',
        'countdown': '00:04',
      },
    });

    expect(decoded?.eventType, InboundEventType.sessionState);
    expect(decoded?.data['countdown'], '00:04');
  });

  test('decodes flag state messages into a typed event', () {
    final decoded = PubSubMessageCodec.decodeInbound({
      'type': 'message',
      'event': 'flag.state',
      'data': {
        'holderLabel': 'Duck 4',
      },
    });

    expect(decoded?.eventType, InboundEventType.flagState);
    expect(decoded?.data['holderLabel'], 'Duck 4');
  });

  test('decodes ack messages into a typed event', () {
    final decoded = PubSubMessageCodec.decodeInbound({
      'type': 'ack',
      'ackId': 7,
      'success': true,
    });

    expect(decoded?.eventType, InboundEventType.ack);
    expect(decoded?.data['ackId'], 7);
    expect(decoded?.data['success'], true);
  });
}
