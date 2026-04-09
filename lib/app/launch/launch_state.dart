import 'package:rubberduck_flutter/app/runtime/runtime_controller_config.dart';

sealed class LaunchState {
  const LaunchState();
}

final class LaunchWaiting extends LaunchState {
  const LaunchWaiting(this.message);

  final String message;
}

final class LaunchResolved extends LaunchState {
  const LaunchResolved(this.runtimeConfig);

  final RuntimeControllerConfig runtimeConfig;
}
