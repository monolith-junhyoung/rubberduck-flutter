# RubberDuck Controller App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first playable mobile controller app for `청소난투`, centered on one-hand portrait control, hold-to-activate gyro input, minimal session status, and Azure Web PubSub event delivery.

**Architecture:** Keep the app as a thin controller client. UI handles entry and display, application logic coordinates join/control flow, domain models represent vectors and session state, and infrastructure handles Azure Web PubSub token/bootstrap and realtime messaging. Movement stays vector-based in the app and can be resolved to 8 directions by the server.

**Tech Stack:** Flutter, Dart, Material 3, sensor package for motion input, `web_socket_channel` or equivalent WebSocket transport, backend-issued Azure Web PubSub connection info, Flutter test.

---

## File Structure

### Existing files to modify

- Modify: `lib/app/app.dart`
- Modify: `lib/main.dart`
- Modify: `lib/features/controller/presentation/controller_home_page.dart`
- Modify: `README.md`

### New files to create

- Create: `lib/app/theme/app_colors.dart`
- Create: `lib/app/theme/app_theme.dart`
- Create: `lib/core/models/connection_state.dart`
- Create: `lib/core/models/control_vector.dart`
- Create: `lib/core/models/session_join_request.dart`
- Create: `lib/core/models/controller_move_event.dart`
- Create: `lib/core/models/controller_stop_event.dart`
- Create: `lib/core/models/flag_state.dart`
- Create: `lib/features/controller/application/controller_view_model.dart`
- Create: `lib/features/controller/application/controller_view_state.dart`
- Create: `lib/features/controller/application/gyro_input_service.dart`
- Create: `lib/features/controller/application/move_transmission_policy.dart`
- Create: `lib/features/controller/presentation/widgets/join_overlay.dart`
- Create: `lib/features/controller/presentation/widgets/status_bar.dart`
- Create: `lib/features/controller/presentation/widgets/gyro_hold_pad.dart`
- Create: `lib/features/controller/presentation/widgets/correction_controls.dart`
- Create: `lib/features/controller/presentation/widgets/vector_feedback.dart`
- Create: `lib/features/controller/domain/direction_resolver.dart`
- Create: `lib/infrastructure/pubsub/pubsub_client.dart`
- Create: `lib/infrastructure/pubsub/pubsub_config.dart`
- Create: `lib/infrastructure/pubsub/pubsub_message_codec.dart`
- Create: `lib/infrastructure/pubsub/session_bootstrap_api.dart`
- Create: `test/features/controller/application/controller_view_model_test.dart`
- Create: `test/features/controller/domain/direction_resolver_test.dart`
- Create: `test/features/controller/application/move_transmission_policy_test.dart`
- Create: `test/features/controller/presentation/controller_home_page_test.dart`

### Responsibility map

- `app/theme/*`: selected `Mini Control Room` theme tokens and app-wide theme wiring
- `core/models/*`: app-wide value objects and transport payloads
- `features/controller/application/*`: join flow, hold/gyro state, publish timing policy
- `features/controller/domain/*`: pure movement math and 8-direction resolution rules
- `features/controller/presentation/*`: overlay, status bar, hold area, correction buttons
- `infrastructure/pubsub/*`: Azure Web PubSub bootstrap and message transport
- `test/*`: domain, application, and widget tests for the controller flow

## Task 1: Lock the visual system to Mini Control Room

**Files:**
- Create: `lib/app/theme/app_colors.dart`
- Create: `lib/app/theme/app_theme.dart`
- Modify: `lib/app/app.dart`

- [ ] **Step 1: Write the failing widget expectation for the selected theme**

Create `test/features/controller/presentation/controller_home_page_test.dart` with assertions that expect:

```dart
expect(find.text('Duck Control'), findsOneWidget);
expect(find.text('Hold to steer'), findsOneWidget);
```

- [ ] **Step 2: Run the widget test to verify it fails**

Run:

```bash
flutter test test/features/controller/presentation/controller_home_page_test.dart
```

Expected: FAIL because the current screen still uses placeholder copy and the themed widgets do not exist yet.

- [ ] **Step 3: Add theme tokens**

Create `lib/app/theme/app_colors.dart` with constants such as:

```dart
abstract final class AppColors {
  static const bgTop = Color(0xFF08111F);
  static const bgBottom = Color(0xFF050914);
  static const panel = Color(0xFF111A2C);
  static const panelBorder = Color(0xFF23324C);
  static const accent = Color(0xFF7AA8FF);
  static const duckGlow = Color(0x66FEE064);
}
```

- [ ] **Step 4: Wire the app theme**

Create `lib/app/theme/app_theme.dart` and update `lib/app/app.dart` so the app theme reflects:

- dark navy scaffold
- rounded cards
- muted borders
- blue accent
- bright type with soft contrast

- [ ] **Step 5: Run the widget test to verify the theme-facing copy is now present**

Run:

```bash
flutter test test/features/controller/presentation/controller_home_page_test.dart
```

Expected: PASS for copy and structure assertions.

- [ ] **Step 6: Commit**

```bash
git add lib/app/theme/app_colors.dart lib/app/theme/app_theme.dart lib/app/app.dart test/features/controller/presentation/controller_home_page_test.dart
git commit -m "feat(ui): add mini control room theme"
```

## Task 2: Replace the placeholder home screen with the approved portrait controller layout

**Files:**
- Modify: `lib/features/controller/presentation/controller_home_page.dart`
- Create: `lib/features/controller/presentation/widgets/join_overlay.dart`
- Create: `lib/features/controller/presentation/widgets/status_bar.dart`
- Create: `lib/features/controller/presentation/widgets/gyro_hold_pad.dart`
- Create: `lib/features/controller/presentation/widgets/correction_controls.dart`
- Create: `lib/features/controller/presentation/widgets/vector_feedback.dart`
- Test: `test/features/controller/presentation/controller_home_page_test.dart`

- [ ] **Step 1: Expand the widget test for the approved layout**

Add expectations for:

```dart
expect(find.text('연결 상태'), findsOneWidget);
expect(find.text('카운트다운'), findsOneWidget);
expect(find.text('현재 깃발'), findsOneWidget);
expect(find.text('입장하기'), findsOneWidget);
expect(find.text('좌'), findsOneWidget);
expect(find.text('정지'), findsOneWidget);
expect(find.text('우'), findsOneWidget);
```

- [ ] **Step 2: Run the widget test to verify it fails**

Run:

```bash
flutter test test/features/controller/presentation/controller_home_page_test.dart
```

Expected: FAIL because the current layout does not match the approved structure.

- [ ] **Step 3: Split the screen into focused widgets**

Implement:

- `JoinOverlay`
- `StatusBar`
- `GyroHoldPad`
- `CorrectionControls`
- `VectorFeedback`

Make `ControllerHomePage` assemble them into:

- top status bar
- center hold-to-steer area
- bottom `좌 / 정지 / 우`
- overlay for name + session code

- [ ] **Step 4: Add placeholder visual details from the spec**

Add:

- subtle grid background
- rounded bordered panels
- glowing duck focal element in the hold area
- `Hold to steer` helper copy

- [ ] **Step 5: Run the widget test to verify the screen structure passes**

Run:

```bash
flutter test test/features/controller/presentation/controller_home_page_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/controller/presentation/controller_home_page.dart lib/features/controller/presentation/widgets/join_overlay.dart lib/features/controller/presentation/widgets/status_bar.dart lib/features/controller/presentation/widgets/gyro_hold_pad.dart lib/features/controller/presentation/widgets/correction_controls.dart lib/features/controller/presentation/widgets/vector_feedback.dart test/features/controller/presentation/controller_home_page_test.dart
git commit -m "feat(controller): build portrait control layout"
```

## Task 3: Add the domain movement model and 8-direction resolution

**Files:**
- Create: `lib/core/models/control_vector.dart`
- Create: `lib/core/models/connection_state.dart`
- Create: `lib/features/controller/domain/direction_resolver.dart`
- Modify: `lib/core/models/movement_command.dart`
- Test: `test/features/controller/domain/direction_resolver_test.dart`

- [ ] **Step 1: Write failing domain tests for vector resolution**

Create tests like:

```dart
expect(resolveDirection(const ControlVector(x: 0, y: 0)), MovementDirection.idle);
expect(resolveDirection(const ControlVector(x: 0.8, y: 0.7)), MovementDirection.upRight);
expect(resolveDirection(const ControlVector(x: -0.9, y: 0.1)), MovementDirection.left);
```

- [ ] **Step 2: Run the domain test to verify it fails**

Run:

```bash
flutter test test/features/controller/domain/direction_resolver_test.dart
```

Expected: FAIL because the vector model and resolver do not exist.

- [ ] **Step 3: Create `ControlVector` and direction resolution rules**

Implement:

- normalized `x` and `y`
- `magnitude`
- dead zone handling
- 8-direction resolution

Keep the resolver pure and stateless.

- [ ] **Step 4: Update transport-facing movement model**

Refactor `lib/core/models/movement_command.dart` so it carries:

- vector data
- resolved direction
- `active`
- `source`
- timestamp

- [ ] **Step 5: Run the domain test to verify resolution behavior passes**

Run:

```bash
flutter test test/features/controller/domain/direction_resolver_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/models/control_vector.dart lib/core/models/connection_state.dart lib/features/controller/domain/direction_resolver.dart lib/core/models/movement_command.dart test/features/controller/domain/direction_resolver_test.dart
git commit -m "feat(domain): add vector movement model"
```

## Task 4: Add the hold-to-activate gyro interaction model

**Files:**
- Create: `lib/features/controller/application/gyro_input_service.dart`
- Create: `lib/features/controller/application/controller_view_state.dart`
- Create: `lib/features/controller/application/controller_view_model.dart`
- Modify: `lib/features/controller/presentation/widgets/gyro_hold_pad.dart`
- Test: `test/features/controller/application/controller_view_model_test.dart`

- [ ] **Step 1: Write failing application tests for hold behavior**

Cover:

- hold start activates gyro
- hold release emits stop state
- inactive state keeps vector idle

Example:

```dart
viewModel.onHoldStarted();
expect(viewModel.state.gyroHoldActive, isTrue);

viewModel.onHoldEnded();
expect(viewModel.state.gyroHoldActive, isFalse);
expect(viewModel.state.currentVector.isIdle, isTrue);
```

- [ ] **Step 2: Run the application test to verify it fails**

Run:

```bash
flutter test test/features/controller/application/controller_view_model_test.dart
```

Expected: FAIL because the view model and gyro service do not exist.

- [ ] **Step 3: Build the controller state coordinator**

Add:

- `ControllerViewState`
- `ControllerViewModel`
- methods for join fields, hold state, correction button input, connection status

- [ ] **Step 4: Add a gyro input abstraction**

`GyroInputService` should expose a stream of motion samples. Keep the first implementation behind an abstraction so tests can fake it.

- [ ] **Step 5: Connect the hold pad to the view model**

When the user presses and holds:

- activate gyro capture
- update vector feedback
- on release, reset to stop

- [ ] **Step 6: Run the application test to verify hold behavior passes**

Run:

```bash
flutter test test/features/controller/application/controller_view_model_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/controller/application/gyro_input_service.dart lib/features/controller/application/controller_view_state.dart lib/features/controller/application/controller_view_model.dart lib/features/controller/presentation/widgets/gyro_hold_pad.dart test/features/controller/application/controller_view_model_test.dart
git commit -m "feat(input): add hold-to-activate gyro flow"
```

## Task 5: Add correction button behavior and stop safety

**Files:**
- Modify: `lib/features/controller/application/controller_view_model.dart`
- Modify: `lib/features/controller/presentation/widgets/correction_controls.dart`
- Test: `test/features/controller/application/controller_view_model_test.dart`

- [ ] **Step 1: Add failing tests for correction buttons**

Cover:

- left button forces negative x correction
- right button forces positive x correction
- stop button clears active motion immediately

- [ ] **Step 2: Run the application test to verify it fails**

Run:

```bash
flutter test test/features/controller/application/controller_view_model_test.dart
```

Expected: FAIL for the new correction button cases.

- [ ] **Step 3: Implement correction control actions**

Rules:

- left/right inject short-lived correction vectors
- stop overrides gyro state immediately
- stop must clear outgoing active motion

- [ ] **Step 4: Run the application test to verify correction behavior passes**

Run:

```bash
flutter test test/features/controller/application/controller_view_model_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/controller/application/controller_view_model.dart lib/features/controller/presentation/widgets/correction_controls.dart test/features/controller/application/controller_view_model_test.dart
git commit -m "feat(input): add correction controls"
```

## Task 6: Add the move transmission policy

**Files:**
- Create: `lib/features/controller/application/move_transmission_policy.dart`
- Modify: `lib/features/controller/application/controller_view_model.dart`
- Test: `test/features/controller/application/move_transmission_policy_test.dart`

- [ ] **Step 1: Write failing tests for the mixed transmission policy**

Cover:

- periodic send when active
- immediate send on large direction change
- no send when idle and unchanged

Example:

```dart
expect(policy.shouldSend(now: t1, lastSentAt: t0, current: vector, previous: vector), isTrue);
expect(policy.shouldSend(now: tSmall, lastSentAt: t0, current: changedVector, previous: oldVector), isTrue);
```

- [ ] **Step 2: Run the policy test to verify it fails**

Run:

```bash
flutter test test/features/controller/application/move_transmission_policy_test.dart
```

Expected: FAIL because the policy does not exist.

- [ ] **Step 3: Implement the mixed send policy**

Policy requirements:

- send every fixed interval while active
- send immediately on meaningful vector change
- suppress redundant idle traffic

- [ ] **Step 4: Integrate the policy into the view model**

The view model should ask the policy whether to emit `controller.move` or `controller.stop`.

- [ ] **Step 5: Run the policy test to verify it passes**

Run:

```bash
flutter test test/features/controller/application/move_transmission_policy_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/controller/application/move_transmission_policy.dart lib/features/controller/application/controller_view_model.dart test/features/controller/application/move_transmission_policy_test.dart
git commit -m "feat(network): add move transmission policy"
```

## Task 7: Add join flow and local state simulation before realtime integration

**Files:**
- Create: `lib/core/models/session_join_request.dart`
- Create: `lib/core/models/flag_state.dart`
- Modify: `lib/features/controller/application/controller_view_model.dart`
- Modify: `lib/features/controller/presentation/widgets/join_overlay.dart`
- Test: `test/features/controller/application/controller_view_model_test.dart`

- [ ] **Step 1: Add failing tests for join validation**

Cover:

- empty name rejected
- empty session code rejected
- valid fields enter submitting state

- [ ] **Step 2: Run the application test to verify it fails**

Run:

```bash
flutter test test/features/controller/application/controller_view_model_test.dart
```

Expected: FAIL for join validation cases.

- [ ] **Step 3: Implement join input state and mock session state**

Before realtime wiring, simulate:

- connection state transitions
- countdown sample values
- current flag holder updates

This gives a working local demo before backend integration.

- [ ] **Step 4: Run the application test to verify join behavior passes**

Run:

```bash
flutter test test/features/controller/application/controller_view_model_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/models/session_join_request.dart lib/core/models/flag_state.dart lib/features/controller/application/controller_view_model.dart lib/features/controller/presentation/widgets/join_overlay.dart test/features/controller/application/controller_view_model_test.dart
git commit -m "feat(session): add join overlay flow"
```

## Task 8: Add Azure Web PubSub bootstrap and client transport

**Files:**
- Create: `lib/infrastructure/pubsub/pubsub_config.dart`
- Create: `lib/infrastructure/pubsub/session_bootstrap_api.dart`
- Create: `lib/infrastructure/pubsub/pubsub_client.dart`
- Create: `lib/infrastructure/pubsub/pubsub_message_codec.dart`
- Modify: `lib/features/controller/application/controller_view_model.dart`
- Test: `test/features/controller/application/controller_view_model_test.dart`

- [ ] **Step 1: Add failing tests around connection state transitions**

Cover:

- join success updates connection to `connecting` then `connected`
- dropped socket moves to `reconnecting`
- reconnect failure ends at `disconnected`

- [ ] **Step 2: Run the application test to verify it fails**

Run:

```bash
flutter test test/features/controller/application/controller_view_model_test.dart
```

Expected: FAIL because transport and connection coordination are not wired.

- [ ] **Step 3: Implement bootstrap flow**

`SessionBootstrapApi` should fetch backend-issued:

- Web PubSub URL
- access token
- player assignment metadata if available

- [ ] **Step 4: Implement the Web PubSub client**

`PubSubClient` should support:

- connect
- disconnect
- reconnect
- publish JSON message
- subscribe to inbound messages

- [ ] **Step 5: Implement message encoding**

`PubSubMessageCodec` should serialize:

- `session.join`
- `controller.move`
- `controller.stop`

and deserialize:

- `player.assignment`
- `session.state`
- `flag.state`

- [ ] **Step 6: Wire transport into the view model**

Replace the local-only simulation path with:

- join request -> bootstrap -> connect
- movement emits outbound realtime events
- inbound state updates feed the UI

- [ ] **Step 7: Run the application test to verify connection behavior passes**

Run:

```bash
flutter test test/features/controller/application/controller_view_model_test.dart
```

Expected: PASS with fake transport/bootstrap implementations.

- [ ] **Step 8: Commit**

```bash
git add lib/infrastructure/pubsub/pubsub_config.dart lib/infrastructure/pubsub/session_bootstrap_api.dart lib/infrastructure/pubsub/pubsub_client.dart lib/infrastructure/pubsub/pubsub_message_codec.dart lib/features/controller/application/controller_view_model.dart test/features/controller/application/controller_view_model_test.dart
git commit -m "feat(pubsub): add realtime transport integration"
```

## Task 9: Add lifecycle safety and stop-on-background behavior

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/features/controller/application/controller_view_model.dart`
- Modify: `lib/features/controller/presentation/controller_home_page.dart`
- Test: `test/features/controller/application/controller_view_model_test.dart`

- [ ] **Step 1: Add failing tests for safety behavior**

Cover:

- app background triggers stop
- touch release triggers stop
- reconnect does not auto-resume movement

- [ ] **Step 2: Run the application test to verify it fails**

Run:

```bash
flutter test test/features/controller/application/controller_view_model_test.dart
```

Expected: FAIL for lifecycle/safety cases.

- [ ] **Step 3: Implement lifecycle hooks**

Use Flutter lifecycle observation so the app:

- stops on pause/inactive
- requires explicit re-hold after returning

- [ ] **Step 4: Run the application test to verify safety behavior passes**

Run:

```bash
flutter test test/features/controller/application/controller_view_model_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/features/controller/application/controller_view_model.dart lib/features/controller/presentation/controller_home_page.dart test/features/controller/application/controller_view_model_test.dart
git commit -m "feat(safety): stop movement on lifecycle changes"
```

## Task 10: Update README to match the implemented architecture

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update README implementation status**

Document:

- final visual direction
- hold-to-steer interaction
- vector movement model
- Azure Web PubSub role
- test strategy

- [ ] **Step 2: Review README for drift against the spec and implementation plan**

Check that MQTT references are removed and the app purpose matches the selected design.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: align readme with controller architecture"
```

## Final verification sweep

**Files:**
- Test: `test/features/controller/application/controller_view_model_test.dart`
- Test: `test/features/controller/domain/direction_resolver_test.dart`
- Test: `test/features/controller/application/move_transmission_policy_test.dart`
- Test: `test/features/controller/presentation/controller_home_page_test.dart`

- [ ] **Step 1: Run the focused controller test suite**

Run:

```bash
flutter test test/features/controller/domain/direction_resolver_test.dart test/features/controller/application/move_transmission_policy_test.dart test/features/controller/application/controller_view_model_test.dart test/features/controller/presentation/controller_home_page_test.dart
```

Expected: PASS.

- [ ] **Step 2: Run the full Flutter test suite**

Run:

```bash
flutter test
```

Expected: PASS.

- [ ] **Step 3: Commit final integrated state**

```bash
git add .
git commit -m "feat(controller): complete first playable mobile controller"
```

## Notes for implementation

- Keep the first gyro integration abstracted behind a service so simulator/test mode remains possible.
- Prefer deterministic fake motion sources in tests instead of real sensor streams.
- Do not couple widget code directly to Web PubSub transport classes.
- Keep the stop action authoritative and side-effect free from the widget layer outward.
- Treat server-side 8-direction resolution as a derived interpretation, not the source of truth.
