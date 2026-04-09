import 'package:flutter_test/flutter_test.dart';
import 'package:rubberduck_flutter/src/core/models/session_join_request.dart';
import 'package:rubberduck_flutter/src/features/duck_pilot/data/session_bootstrap_api.dart';

void main() {
  test('creates pubsub config from direct client access url', () async {
    const accessUrl =
        'wss://monolith.webpubsub.azure.com/client/hubs/rubberduck?access_token=test-token';

    final api = DirectClientAccessBootstrapApi(
      clientAccessUrl: accessUrl,
    );

    final config = await api.createConnection(
      SessionBootstrapRequest.fromJoinRequest(
        const SessionJoinRequest(
          playerName: 'duck pilot',
          sessionCode: 'BATH-01',
          deviceId: 'device-1',
        ),
      ),
    );

    expect(config.clientAccessUrl, accessUrl);
    expect(config.hub, 'rubberduck');
    expect(config.group, 'BATH-01');
    expect(config.userId, 'duck pilot');
  });
}
