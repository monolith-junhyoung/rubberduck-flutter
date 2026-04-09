class SessionJoinRequest {
  const SessionJoinRequest({
    required this.playerName,
    required this.sessionCode,
    required this.deviceId,
  });

  final String playerName;
  final String sessionCode;
  final String deviceId;
}
