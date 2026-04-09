import 'package:rubberduck_flutter/src/core/config/runtime_configuration.dart';

sealed class AppRouterState {
  const AppRouterState();
}

final class AppRouterWaiting extends AppRouterState {
  const AppRouterWaiting(this.message);

  final String message;
}

final class AppRouterResolved extends AppRouterState {
  const AppRouterResolved(this.runtimeConfig);

  final RuntimeConfiguration runtimeConfig;
}
