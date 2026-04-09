const kRubberDuckPubSubClientUrl =
    'wss://monolith.webpubsub.azure.com/client/hubs/rubburduck?access_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJ3c3M6Ly9tb25vbGl0aC53ZWJwdWJzdWIuYXp1cmUuY29tL2NsaWVudC9odWJzL3J1YmJ1cmR1Y2siLCJpYXQiOjE3NzU2MTQxMzIsImV4cCI6MTc3NTY5ODEzMiwicm9sZSI6WyJ3ZWJwdWJzdWIuc2VuZFRvR3JvdXAiLCJ3ZWJwdWJzdWIuam9pbkxlYXZlR3JvdXAiXSwic3ViIjoibW9ub2xpdGgzIn0.w4Eh3i3x8mlu0KSdGZKuahQYWDqoplboPTYIfNKlTbY';

class RuntimeControllerConfig {
  const RuntimeControllerConfig({this.pubSubClientAccessUrl = kRubberDuckPubSubClientUrl, this.autoJoinOnStart = true});

  factory RuntimeControllerConfig.fromEnvironment() {
    return const RuntimeControllerConfig();
  }

  final String pubSubClientAccessUrl;
  final bool autoJoinOnStart;

  bool get isRealtimeReady => pubSubClientAccessUrl.isNotEmpty;

  String get runtimeModeLabel => isRealtimeReady ? '직접 URL 모드' : '로컬 모드';

  String get statusLabel => isRealtimeReady ? '실시간 준비됨' : '로컬 모드';
}
