import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rubberduck_flutter/core/models/control_vector.dart';
import 'package:rubberduck_flutter/core/models/movement_command.dart';
import 'package:rubberduck_flutter/features/controller/presentation/widgets/gyro_hold_pad.dart';

void main() {
  testWidgets('keeps hold active while finger moves inside a scroll view', (
    tester,
  ) async {
    var startCount = 0;
    var endCount = 0;
    var active = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      active ? 'active' : 'idle',
                      key: const Key('hold-state'),
                    ),
                    const SizedBox(height: 12),
                    GyroHoldPad(
                      vector: const ControlVector(x: 0, y: 0, active: false),
                      direction: MovementDirection.idle,
                      isActive: active,
                      onHoldStart: () => setState(() {
                        active = true;
                        startCount += 1;
                      }),
                      onHoldEnd: () => setState(() {
                        active = false;
                        endCount += 1;
                      }),
                    ),
                    const SizedBox(height: 600),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    final pad = find.byType(GyroHoldPad);
    final holdState = find.byKey(const Key('hold-state'));

    expect((tester.widget<Text>(holdState)).data, 'idle');

    final gesture = await tester.startGesture(tester.getCenter(pad));
    await tester.pump();

    expect((tester.widget<Text>(holdState)).data, 'active');
    expect(startCount, 1);
    expect(endCount, 0);

    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();

    expect((tester.widget<Text>(holdState)).data, 'active');
    expect(endCount, 0);

    await gesture.up();
    await tester.pump();

    expect((tester.widget<Text>(holdState)).data, 'idle');
    expect(endCount, 1);
  });
}
