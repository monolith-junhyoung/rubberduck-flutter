import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/runtime/runtime_controller_config.dart';

void main() {
  runApp(
    RubberDuckApp(
      runtimeConfig: RuntimeControllerConfig.fromEnvironment(),
    ),
  );
}
