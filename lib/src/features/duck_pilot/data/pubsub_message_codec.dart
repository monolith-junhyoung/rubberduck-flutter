import 'package:rubberduck_flutter/src/core/models/movement_command.dart';
import 'package:rubberduck_flutter/src/core/models/session_join_request.dart';

enum InboundEventType {
  sessionState,
  flagState,
  playerAssignment,
  ack,
}

class InboundPubSubEvent {
  const InboundPubSubEvent({
    required this.eventType,
    required this.data,
  });

  final InboundEventType eventType;
  final Map<String, dynamic> data;
}

abstract final class PubSubMessageCodec {
  static Map<String, Object?> encodeJoinGroup(String group, {int? ackId}) {
    return {
      'type': 'joinGroup',
      'group': group,
      if (ackId != null) 'ackId': ackId,
    };
  }

  static Map<String, Object?> encodeJoin(
    SessionJoinRequest request, {
    int? ackId,
  }) {
    return {
      'type': 'sendToGroup',
      'group': request.sessionCode,
      if (ackId != null) 'ackId': ackId,
      'dataType': 'json',
      'data': {
        'type': 'join',
        'playerId': request.playerName,
        'sessionCode': request.sessionCode,
      },
    };
  }

  static Map<String, Object?> encodeMove(
    MovementCommand command, {
    int? ackId,
  }) {
    return {
      'type': 'sendToGroup',
      'group': command.sessionCode,
      if (ackId != null) 'ackId': ackId,
      'dataType': 'json',
      'data': {
        'type': 'controller.move',
        'playerId': command.playerId,
        'sessionCode': command.sessionCode,
        'direction': command.direction.name,
      },
    };
  }

  static Map<String, Object?> encodeStop(
    MovementCommand command,
    String reason, {
    int? ackId,
  }) {
    return {
      'type': 'sendToGroup',
      'group': command.sessionCode,
      if (ackId != null) 'ackId': ackId,
      'dataType': 'json',
      'data': {
        'type': 'controller.stop',
        'playerId': command.playerId,
        'sessionCode': command.sessionCode,
        'direction': MovementDirection.idle.name,
      },
    };
  }

  static InboundPubSubEvent? decodeInbound(Map<String, dynamic> message) {
    if (message['type'] == 'ack') {
      return InboundPubSubEvent(
        eventType: InboundEventType.ack,
        data: Map<String, dynamic>.from(message),
      );
    }

    final event = message['event'];
    final data = message['data'];
    if (event is! String || data is! Map) {
      return null;
    }

    final payload = Map<String, dynamic>.from(data.cast<String, dynamic>());
    switch (event) {
      case 'session.state':
        return InboundPubSubEvent(
          eventType: InboundEventType.sessionState,
          data: payload,
        );
      case 'flag.state':
        return InboundPubSubEvent(
          eventType: InboundEventType.flagState,
          data: payload,
        );
      case 'player.assignment':
        return InboundPubSubEvent(
          eventType: InboundEventType.playerAssignment,
          data: payload,
        );
      default:
        return null;
    }
  }
}
