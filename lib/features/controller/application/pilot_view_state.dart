import '../../../core/models/control_vector.dart';
import '../../../core/models/movement_command.dart';

class PilotViewState {
  const PilotViewState({
    required this.playerId,
    required this.playerName,
    required this.sessionCode,
    required this.errorMessage,
    required this.isJoined,
    required this.connectionLabel,
    required this.countdownLabel,
    required this.flagHolderLabel,
    required this.gyroHoldActive,
    required this.currentVector,
    required this.resolvedDirection,
    required this.debugLogs,
    required this.connectionSummary,
    required this.lastSendSummary,
    required this.lastReceiveSummary,
    required this.lastAckSummary,
    required this.showReconnectAction,
  });

  factory PilotViewState.initial() {
    return const PilotViewState(
      playerName: '',
      playerId: 'local-player',
      sessionCode: '',
      errorMessage: '',
      isJoined: false,
      connectionLabel: '입장 대기',
      countdownLabel: '--:--',
      flagHolderLabel: '-',
      gyroHoldActive: false,
      currentVector: ControlVector(x: 0, y: 0, active: false),
      resolvedDirection: MovementDirection.idle,
      debugLogs: <String>[],
      connectionSummary: 'idle',
      lastSendSummary: '-',
      lastReceiveSummary: '-',
      lastAckSummary: '-',
      showReconnectAction: false,
    );
  }

  final String playerId;
  final String playerName;
  final String sessionCode;
  final String errorMessage;
  final bool isJoined;
  final String connectionLabel;
  final String countdownLabel;
  final String flagHolderLabel;
  final bool gyroHoldActive;
  final ControlVector currentVector;
  final MovementDirection resolvedDirection;
  final List<String> debugLogs;
  final String connectionSummary;
  final String lastSendSummary;
  final String lastReceiveSummary;
  final String lastAckSummary;
  final bool showReconnectAction;

  PilotViewState copyWith({
    String? playerId,
    String? playerName,
    String? sessionCode,
    String? errorMessage,
    bool? isJoined,
    String? connectionLabel,
    String? countdownLabel,
    String? flagHolderLabel,
    bool? gyroHoldActive,
    ControlVector? currentVector,
    MovementDirection? resolvedDirection,
    List<String>? debugLogs,
    String? connectionSummary,
    String? lastSendSummary,
    String? lastReceiveSummary,
    String? lastAckSummary,
    bool? showReconnectAction,
  }) {
    return PilotViewState(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      sessionCode: sessionCode ?? this.sessionCode,
      errorMessage: errorMessage ?? this.errorMessage,
      isJoined: isJoined ?? this.isJoined,
      connectionLabel: connectionLabel ?? this.connectionLabel,
      countdownLabel: countdownLabel ?? this.countdownLabel,
      flagHolderLabel: flagHolderLabel ?? this.flagHolderLabel,
      gyroHoldActive: gyroHoldActive ?? this.gyroHoldActive,
      currentVector: currentVector ?? this.currentVector,
      resolvedDirection: resolvedDirection ?? this.resolvedDirection,
      debugLogs: debugLogs ?? this.debugLogs,
      connectionSummary: connectionSummary ?? this.connectionSummary,
      lastSendSummary: lastSendSummary ?? this.lastSendSummary,
      lastReceiveSummary: lastReceiveSummary ?? this.lastReceiveSummary,
      lastAckSummary: lastAckSummary ?? this.lastAckSummary,
      showReconnectAction: showReconnectAction ?? this.showReconnectAction,
    );
  }
}
