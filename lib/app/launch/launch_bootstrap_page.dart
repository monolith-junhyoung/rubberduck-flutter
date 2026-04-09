import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../features/controller/presentation/pilot_page.dart';
import '../runtime/runtime_controller_config.dart';
import '../theme/app_colors.dart';
import 'launch_link_parser.dart';
import 'launch_state.dart';

class LaunchBootstrapPage extends StatefulWidget {
  const LaunchBootstrapPage({
    super.key,
    this.runtimeConfig = const RuntimeControllerConfig(),
    this.initialLaunchUriProvider,
    this.launchLinkStream,
    this.resolvedPageBuilder,
  });

  final RuntimeControllerConfig runtimeConfig;
  final Future<Uri?> Function()? initialLaunchUriProvider;
  final Stream<Uri>? launchLinkStream;
  final Widget Function(RuntimeControllerConfig)? resolvedPageBuilder;

  @override
  State<LaunchBootstrapPage> createState() => _LaunchBootstrapPageState();
}

class _LaunchBootstrapPageState extends State<LaunchBootstrapPage> {
  final AppLinks _appLinks = AppLinks();
  LaunchState _state = const LaunchWaiting('launch 링크를 기다리는 중...');
  StreamSubscription<Uri>? _linkStream;
  bool _isShowingRelaunchDialog = false;

  @override
  void initState() {
    super.initState();
    if (widget.runtimeConfig.isRealtimeReady) {
      _state = LaunchResolved(widget.runtimeConfig);
      return;
    }
    unawaited(_observeLaunchLinks());
  }

  Future<void> _observeLaunchLinks() async {
    try {
      final initialLinkProvider =
          widget.initialLaunchUriProvider ?? _loadInitialLaunchUri;
      final initialLink = await initialLinkProvider();
      if (!mounted) {
        return;
      }
      await _applyLaunchLink(initialLink);

      final stream = widget.launchLinkStream ?? _loadLaunchStream();
      _linkStream = stream.listen(_onLaunchLink);
    } on Exception {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = const LaunchWaiting('링크 수신 초기화 중 오류가 발생했습니다.');
      });
    }
  }

  void _onLaunchLink(Uri? uri) {
    unawaited(_applyLaunchLink(uri));
  }

  Future<void> _applyLaunchLink(Uri? uri) async {
    if (!mounted) {
      return;
    }
    final parseResult = LaunchLinkParser.parseUri(uri);
    if (!parseResult.isValid) {
      final message = parseResult is LaunchParseFailure
          ? parseResult.message
          : '유효하지 않은 링크입니다.';
      if (_state is LaunchResolved) {
        return;
      }
      setState(() {
        _state = LaunchWaiting(message);
      });
      return;
    }

    final nextConfig = (parseResult as LaunchParseSuccess).runtimeConfig;
    final currentState = _state;
    if (currentState is LaunchResolved &&
        currentState.runtimeConfig.pubSubClientAccessUrl !=
            nextConfig.pubSubClientAccessUrl) {
      final shouldSwitch = await _showRelaunchConfirm();
      if (!shouldSwitch) {
        return;
      }
    }

    if (!mounted) {
      return;
    }
    if (currentState is LaunchResolved &&
        currentState.runtimeConfig.pubSubClientAccessUrl ==
            nextConfig.pubSubClientAccessUrl) {
      return;
    }

    setState(() {
      _state = LaunchResolved(nextConfig);
    });
  }

  Future<bool> _showRelaunchConfirm() async {
    if (_isShowingRelaunchDialog) {
      return false;
    }
    _isShowingRelaunchDialog = true;
    final shouldSwitch = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('세션 변경 확인'),
            content: const Text('새 런치 링크가 도착했습니다. 현재 세션을 바꾸시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('거부'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('연결'),
              ),
            ],
          ),
        ) ??
        false;
    _isShowingRelaunchDialog = false;
    return shouldSwitch;
  }

  Widget _buildResolvedPage() {
    if (widget.resolvedPageBuilder != null) {
      return widget.resolvedPageBuilder!((_state as LaunchResolved).runtimeConfig);
    }

    return PilotPage(
      key: ValueKey((_state as LaunchResolved).runtimeConfig.pubSubClientAccessUrl),
      runtimeConfig: (_state as LaunchResolved).runtimeConfig,
    );
  }

  Future<Uri?> _loadInitialLaunchUri() async {
    final dynamic appLinks = _appLinks;
    try {
      final uri = await appLinks.getInitialAppLink();
      if (uri is Uri) {
        return uri;
      }
      if (uri is String) {
        return Uri.tryParse(uri);
      }
    } on NoSuchMethodError {
      // fallback for newer API names
    }

    try {
      final uri = await appLinks.getInitialUri();
      if (uri is Uri) {
        return uri;
      }
      if (uri is String) {
        return Uri.tryParse(uri);
      }
    } on NoSuchMethodError {
      // fallback for newer API names
    }

    try {
      final uri = await appLinks.getInitialLink();
      if (uri is Uri) {
        return uri;
      }
      if (uri is String) {
        return Uri.tryParse(uri);
      }
    } on NoSuchMethodError {
      return null;
    }

    return null;
  }

  Stream<Uri> _loadLaunchStream() {
    final dynamic appLinks = _appLinks;
    try {
      final stream = appLinks.uriLinkStream;
      if (stream is Stream<Uri>) {
        return stream;
      }
      if (stream is Stream<String>) {
        return stream
            .map((url) => Uri.tryParse(url))
            .where((url) => url != null)
            .cast<Uri>();
      }
    } on NoSuchMethodError {
      return Stream<Uri>.empty();
    }

    return Stream<Uri>.empty();
  }

  @override
  Widget build(BuildContext context) {
    final currentState = _state;
    if (currentState is LaunchResolved) {
      return _buildResolvedPage();
    }
    final message =
        currentState is LaunchWaiting ? currentState.message : 'launch 링크를 기다리는 중...';
    return Scaffold(
      backgroundColor: AppColors.bgBottom,
      body: _LaunchWaitingScreen(message: message),
    );
  }

  @override
  void dispose() {
    _linkStream?.cancel();
    super.dispose();
  }
}

class _LaunchWaitingScreen extends StatelessWidget {
  const _LaunchWaitingScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Card(
            color: const Color(0x19000000),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_tethering_off_rounded, size: 72, color: AppColors.accent),
                  const SizedBox(height: 18),
                  Text(
                    '세션 링크 대기',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'QR 코드에서 launch 링크를 열어 `pubsub_url`이 전달되면\n컨트롤러 화면이 자동으로 시작됩니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
