import 'package:flutter/material.dart';

import 'package:rubberduck_flutter/src/app/app.dart';
import 'package:rubberduck_flutter/src/core/config/runtime_configuration.dart';

void main() {
  runApp(
    RubberDuckApp(
      runtimeConfig: RuntimeConfiguration.fromEnvironment(),
    ),
  );
}
