import 'package:flutter/foundation.dart';
import 'package:rubberduck_flutter/src/core/config/runtime_configuration.dart';

const _kAllowedPubSubHosts = <String>{
  'monolith.webpubsub.azure.com',
};
const _kLaunchDomains = <String>{
  'duckpilot.vercel.app',
};
const _kLaunchScheme = 'rubberduckpilot';
const _kLaunchPath = '/launch';

@immutable
sealed class LaunchParseResult {
  const LaunchParseResult();

  bool get isValid => switch (this) {
        LaunchParseSuccess() => true,
        LaunchParseFailure() => false,
      };
}

@immutable
final class LaunchParseSuccess extends LaunchParseResult {
  const LaunchParseSuccess(this.runtimeConfig);

  final RuntimeConfiguration runtimeConfig;
}

@immutable
final class LaunchParseFailure extends LaunchParseResult {
  const LaunchParseFailure(this.message);

  final String message;
}

abstract class LaunchLinkParser {
  static LaunchParseResult parse(String? rawUri) {
    if (rawUri == null || rawUri.isEmpty) {
      return const LaunchParseFailure('딥링크가 전달되지 않았습니다.');
    }
    final uri = Uri.tryParse(rawUri);
    if (uri == null) {
      return const LaunchParseFailure('딥링크 URL 형식이 유효하지 않습니다.');
    }
    final uriHost = uri.host.toLowerCase();
    final launchDomainMatched = _kLaunchDomains.contains(uriHost);
    final launchSchemeMatched = uri.scheme.toLowerCase() == _kLaunchScheme;
    final launchTarget = uri.path.isNotEmpty ? uri.path : uri.host;
    final launchPath = launchTarget.replaceFirst(RegExp(r'^/+'), '');
    final launchPathMatched = launchPath == _kLaunchPath.replaceFirst('/', '');
    if (!launchPathMatched || !(launchDomainMatched || launchSchemeMatched)) {
      return const LaunchParseFailure('지원하지 않는 launch 도메인입니다.');
    }

    final pubSubUrl = uri.queryParameters['pubsub_url'];
    if (pubSubUrl == null || pubSubUrl.isEmpty) {
      return const LaunchParseFailure('pubsub_url 파라미터가 없습니다.');
    }

    final pubSubUri = Uri.tryParse(pubSubUrl);
    if (pubSubUri == null || pubSubUri.scheme.toLowerCase() != 'wss') {
      return const LaunchParseFailure('pubsub_url은 wss:// URL 이어야 합니다.');
    }
    if (!_kAllowedPubSubHosts.contains(pubSubUri.host)) {
      return const LaunchParseFailure('허용되지 않은 pubsub 호스트입니다.');
    }

    return LaunchParseSuccess(
      RuntimeConfiguration.fromPubSubUrl(pubSubUri.toString()),
    );
  }

  static LaunchParseResult parseUri(Uri? uri) {
    return parse(uri?.toString());
  }
}
