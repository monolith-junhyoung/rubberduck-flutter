import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rubberduck_flutter/app/app.dart';
import 'package:rubberduck_flutter/app/runtime/runtime_controller_config.dart';

void main() {
  testWidgets('renders the approved mini control room layout', (tester) async {
    await tester.pumpWidget(
      const RubberDuckApp(
        runtimeConfig: RuntimeControllerConfig(
          pubSubClientAccessUrl:
              'wss://monolith.webpubsub.azure.com/client/hubs/rubberduck?access_token=test',
          autoJoinOnStart: false,
        ),
      ),
    );

    expect(find.text('Duck Control'), findsOneWidget);
    expect(find.text('Hold to steer'), findsOneWidget);
    expect(find.text('실시간 준비됨'), findsOneWidget);
    expect(find.text('직접 URL 모드'), findsOneWidget);
    expect(find.text('연결 상태'), findsOneWidget);
    expect(find.text('카운트다운'), findsOneWidget);
    expect(find.text('현재 깃발'), findsOneWidget);
    expect(find.text('입장하기'), findsNothing);
    expect(find.text('좌'), findsOneWidget);
    expect(find.text('정지'), findsOneWidget);
    expect(find.text('우'), findsOneWidget);
    expect(find.text('Debug Log'), findsOneWidget);
    expect(find.text('Connection'), findsNothing);
    expect(find.text('Last Send'), findsNothing);
    expect(find.text('Last Recv'), findsNothing);
    expect(find.text('Last Ack'), findsNothing);
    expect(find.text('재연결'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.width == 188 &&
            widget.height == 144 &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/rubber_duck_top.png',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows realtime-ready status when a pubsub url is configured',
      (tester) async {
    await tester.pumpWidget(
      RubberDuckApp(
        runtimeConfig: const RuntimeControllerConfig(
          pubSubClientAccessUrl:
              'wss://monolith.webpubsub.azure.com/client/hubs/rubberduck?access_token=test',
          autoJoinOnStart: false,
        ),
      ),
    );

    expect(find.text('실시간 준비됨'), findsOneWidget);
    expect(find.text('직접 URL 모드'), findsOneWidget);
  });
}
