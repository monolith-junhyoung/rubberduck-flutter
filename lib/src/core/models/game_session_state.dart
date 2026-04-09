import 'player_status.dart';

class GameSessionState {
  const GameSessionState({
    required this.sessionName,
    required this.connectionLabel,
    required this.countdownSeconds,
    required this.lastTriggeredObstacle,
    required this.players,
  });

  final String sessionName;
  final String connectionLabel;
  final int countdownSeconds;
  final String lastTriggeredObstacle;
  final List<PlayerStatus> players;
}
