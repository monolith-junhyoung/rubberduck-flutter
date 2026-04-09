class RuntimeControllerConfig {
  const RuntimeControllerConfig({
    this.pubSubClientAccessUrl = '',
    this.autoJoinOnStart = false,
  });

  factory RuntimeControllerConfig.fromEnvironment() {
    final configuredUrl = const String.fromEnvironment(
      'RUBBERDUCK_PUBSUB_CLIENT_URL',
      defaultValue: '',
    );
    if (configuredUrl.isEmpty) {
      return const RuntimeControllerConfig();
    }
    return RuntimeControllerConfig(
      pubSubClientAccessUrl: configuredUrl,
      autoJoinOnStart: true,
    );
  }

  factory RuntimeControllerConfig.fromPubSubUrl(String pubSubUrl) {
    return RuntimeControllerConfig(
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
