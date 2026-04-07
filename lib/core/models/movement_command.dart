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
    required this.direction,
    required this.x,
    required this.y,
    required this.source,
    required this.sentAt,
  });

  final String playerId;
  final MovementDirection direction;
  final double x;
  final double y;
  final String source;
  final DateTime sentAt;
}
