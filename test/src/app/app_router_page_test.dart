import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rubberduck_flutter/src/app/app_router_page.dart';
import 'package:rubberduck_flutter/src/core/config/runtime_configuration.dart';

const _validLaunchUrl =
    'https://duckpilot.vercel.app/launch?v=1&pubsub_url=wss://monolith.webpubsub.azure.com/client/hubs/rubberduck?access_token=test';
const _secondLaunchUrl =
    'https://duckpilot.vercel.app/launch?v=1&pubsub_url=wss://monolith.webpubsub.azure.com/client/hubs/rubberduck?access_token=next';
const _invalidLaunchUrl = 'https://duckpilot.vercel.app/launch?v=1';
const _invalidSchemaUrl =
    'https://duckpilot.vercel.app/launch?v=1&pubsub_url=http://monolith.webpubsub.azure.com/client/hubs/rubberduck';
const _firstHostLabel = 'wss://monolith.webpubsub.azure.com/client/hubs/rubberduck?access_token=test';
const _secondHostLabel = 'wss://monolith.webpubsub.azure.com/client/hubs/rubberduck?access_token=next';

void main() {
  testWidgets('shows waiting screen when launched without valid link', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const AppRouterPage(
          initialLaunchUriProvider: _missingLaunchUri,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('세션 링크 대기'), findsOneWidget);
    expect(find.text('Hold to steer'), findsNothing);
    expect(
      find.text('pubsub_url 파라미터가 없습니다.'),
      findsOneWidget,
    );
  });

  testWidgets('shows game screen when a valid launch link is supplied initially', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppRouterPage(
          initialLaunchUriProvider: _validLaunchUri,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Duck Control'), findsOneWidget);
    expect(find.text('세션 링크 대기'), findsNothing);
    expect(find.text('Hold to steer'), findsOneWidget);
  });

  testWidgets(
    'switches to game only after a valid link appears in the launch stream',
    (tester) async {
      final controller = StreamController<Uri>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        MaterialApp(
            home: AppRouterPage(
            initialLaunchUriProvider: _missingLaunchUri,
            launchLinkStream: controller.stream,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('세션 링크 대기'), findsOneWidget);
      expect(find.text('Hold to steer'), findsNothing);

      controller.add(Uri.parse(_invalidSchemaUrl));
      await tester.pumpAndSettle();
      expect(
        find.text('pubsub_url은 wss:// URL 이어야 합니다.'),
        findsOneWidget,
      );

      controller.add(Uri.parse(_validLaunchUrl));
      await tester.pumpAndSettle();
      expect(find.text('Duck Control'), findsOneWidget);
      expect(find.text('세션 링크 대기'), findsNothing);
      expect(find.text('Hold to steer'), findsOneWidget);
    },
  );

  testWidgets('asks for confirmation when a new launch link arrives during active session', (
    tester,
  ) async {
    final controller = StreamController<Uri>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      MaterialApp(
        home: AppRouterPage(
          initialLaunchUriProvider: _validLaunchUri,
          launchLinkStream: controller.stream,
          resolvedPageBuilder: _resolvedTestBuilder,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_firstHostLabel), findsOneWidget);

    controller.add(Uri.parse(_secondLaunchUrl));
    await tester.pumpAndSettle();

    expect(find.text('세션 변경 확인'), findsOneWidget);
    expect(find.text('거부'), findsOneWidget);
    expect(find.text('연결'), findsOneWidget);

    await tester.tap(find.text('거부'));
    await tester.pumpAndSettle();

    expect(find.text(_firstHostLabel), findsOneWidget);
    expect(find.text(_secondHostLabel), findsNothing);
  });

  testWidgets('switches session only when relaunched link is confirmed', (
    tester,
  ) async {
    final controller = StreamController<Uri>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      MaterialApp(
        home: AppRouterPage(
          initialLaunchUriProvider: _validLaunchUri,
          launchLinkStream: controller.stream,
          resolvedPageBuilder: _resolvedTestBuilder,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_firstHostLabel), findsOneWidget);

    controller.add(Uri.parse(_secondLaunchUrl));
    await tester.pumpAndSettle();

    await tester.tap(find.text('연결'));
    await tester.pumpAndSettle();

    expect(find.text(_secondHostLabel), findsOneWidget);
    expect(find.text(_firstHostLabel), findsNothing);
  });
}

Future<Uri?> _missingLaunchUri() async => Uri.parse(_invalidLaunchUrl);

Future<Uri?> _validLaunchUri() async => Uri.parse(_validLaunchUrl);

Widget _resolvedTestBuilder(RuntimeConfiguration config) {
  return Text(config.pubSubClientAccessUrl);
}
