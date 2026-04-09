class PlayerStatus {
  const PlayerStatus({
    required this.playerId,
    required this.displayName,
    required this.flagHoldDuration,
    required this.isHoldingFlag,
    required this.hadFlagAtEnd,
    required this.isConnected,
    required this.lastInputLabel,
  });

  final String playerId;
  final String displayName;
  final Duration flagHoldDuration;
  final bool isHoldingFlag;
  final bool hadFlagAtEnd;
  final bool isConnected;
  final String lastInputLabel;
}
