class PubSubConfig {
  const PubSubConfig({
    required this.url,
    required this.accessToken,
    required this.hub,
    required this.group,
    required this.userId,
    this.clientAccessUrl,
  });

  final String url;
  final String accessToken;
  final String hub;
  final String group;
  final String userId;
  final String? clientAccessUrl;
}
