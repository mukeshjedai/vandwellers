import 'package:flutter_test/flutter_test.dart';
import 'package:van_dwellers/services/version_update_service.dart';

void main() {
  group('VersionUpdateService.isRemoteNewer', () {
    test('compares integer build numbers from versions.txt', () {
      expect(
        VersionUpdateService.isRemoteNewer('2', '3.0.0', '1'),
        isTrue,
      );
      expect(
        VersionUpdateService.isRemoteNewer('1', '3.0.0', '1'),
        isFalse,
      );
    });

    test('compares semver strings', () {
      expect(
        VersionUpdateService.isRemoteNewer('3.1.0', '3.0.0', '1'),
        isTrue,
      );
      expect(
        VersionUpdateService.isRemoteNewer('3.0.0', '3.0.0', '1'),
        isFalse,
      );
    });
  });
}
