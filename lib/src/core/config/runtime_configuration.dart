class RuntimeConfiguration {
  const RuntimeConfiguration({
    this.pubSubClientAccessUrl = '',
    this.autoJoinOnStart = false,
  });

  factory RuntimeConfiguration.fromEnvironment() {
    final configuredUrl = const String.fromEnvironment(
      'RUBBERDUCK_PUBSUB_CLIENT_URL',
      defaultValue: '',
    );
    if (configuredUrl.isEmpty) {
      return const RuntimeConfiguration();
    }
    return RuntimeConfiguration(
      pubSubClientAccessUrl: configuredUrl,
      autoJoinOnStart: true,
    );
  }

  factory RuntimeConfiguration.fromPubSubUrl(String pubSubUrl) {
    return RuntimeConfiguration(
      pubSubClientAccessUrl: pubSubUrl,
      autoJoinOnStart: true,
    );
  }

  final String pubSubClientAccessUrl;
  final bool autoJoinOnStart;

  bool get isRealtimeReady => pubSubClientAccessUrl.isNotEmpty;

  String get runtimeModeLabel => isRealtimeReady ? '직접 URL 모드' : '로컬 모드';

  String get statusLabel => isRealtimeReady ? '실시간 준비됨' : '로컬 모드';
}
