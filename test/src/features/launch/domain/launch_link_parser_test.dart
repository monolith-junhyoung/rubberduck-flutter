import 'package:flutter_test/flutter_test.dart';
import 'package:rubberduck_flutter/src/features/launch/domain/launch_link_parser.dart';

void main() {
  test('parses a valid launch URL', () {
    const launchUrl =
        'https://duckpilot.vercel.app/launch?v=1&pubsub_url=wss://monolith.webpubsub.azure.com/client/hubs/rubberduck?access_token=test';
    final result = LaunchLinkParser.parse(launchUrl);

    expect(result, isA<LaunchParseSuccess>());
    result as LaunchParseSuccess;
    expect(result.runtimeConfig.isRealtimeReady, isTrue);
    expect(result.runtimeConfig.autoJoinOnStart, isTrue);
    expect(
      result.runtimeConfig.pubSubClientAccessUrl,
      'wss://monolith.webpubsub.azure.com/client/hubs/rubberduck?access_token=test',
    );
  });

  test('rejects launch URL without pubsub_url', () {
    const launchUrl = 'https://duckpilot.vercel.app/launch?v=1';
    final result = LaunchLinkParser.parse(launchUrl);

    expect(result, isA<LaunchParseFailure>());
  });

  test('rejects launch URL with unsupported wss host', () {
    const launchUrl =
        'https://duckpilot.vercel.app/launch?v=1&pubsub_url=wss://malicious.example.com/endpoint';
    final result = LaunchLinkParser.parse(launchUrl);

    expect(result, isA<LaunchParseFailure>());
  });

  test('accepts custom scheme launch URL', () {
    const launchUrl =
        'rubberduckpilot://launch?pubsub_url=wss://monolith.webpubsub.azure.com/client/hubs/rubberduck';
    final result = LaunchLinkParser.parse(launchUrl);

    expect(result, isA<LaunchParseSuccess>());
  });

  test('rejects non-wss pubsub URL', () {
    const launchUrl =
        'https://duckpilot.vercel.app/launch?v=1&pubsub_url=http://monolith.webpubsub.azure.com/client/hubs/rubberduck';
    final result = LaunchLinkParser.parse(launchUrl);

    expect(result, isA<LaunchParseFailure>());
  });
}
