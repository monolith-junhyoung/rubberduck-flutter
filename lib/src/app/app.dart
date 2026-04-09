import 'package:flutter/material.dart';
import 'package:rubberduck_flutter/src/app/app_router_page.dart';
import 'package:rubberduck_flutter/src/app/theme/app_theme.dart';
import 'package:rubberduck_flutter/src/core/config/runtime_configuration.dart';

class RubberDuckApp extends StatelessWidget {
  const RubberDuckApp({super.key, this.runtimeConfig = const RuntimeConfiguration()});

  final RuntimeConfiguration runtimeConfig;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '욕실의 난',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: AppRouterPage(runtimeConfig: runtimeConfig),
    );
  }
}
