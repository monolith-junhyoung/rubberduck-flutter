import 'package:flutter/material.dart';

import 'launch/launch_bootstrap_page.dart';
import 'runtime/runtime_controller_config.dart';
import 'theme/app_theme.dart';

class RubberDuckApp extends StatelessWidget {
  const RubberDuckApp({super.key, this.runtimeConfig = const RuntimeControllerConfig()});

  final RuntimeControllerConfig runtimeConfig;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '욕실의 난',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: LaunchBootstrapPage(runtimeConfig: runtimeConfig),
    );
  }
}
