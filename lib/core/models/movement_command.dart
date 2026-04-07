import 'control_vector.dart';

enum MovementDirection {
  idle,
  up,
  down,
  left,
  right,
  upLeft,
  upRight,
  downLeft,
  downRight,
}

class MovementCommand {
  const MovementCommand({
    required this.playerId,
    required this.sessionCode,
    required this.vector,
    required this.direction,
    required this.active,
    required this.source,
    required this.sentAt,
  });

  final String playerId;
  final String sessionCode;
  final ControlVector vector;
  final MovementDirection direction;
  final bool active;
  final String source;
  final DateTime sentAt;

  double get x => vector.x;
  double get y => vector.y;
  double get magnitude => vector.magnitude;
}
