import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:epresensi_mobile/api/urls.dart';
import 'package:epresensi_mobile/core/network/pinned_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

enum UpdateType { none, optional, mandatory }

class VersionCheckResult {
  final UpdateType type;
  final String? storeUrl;
  final String latestVersion;

  VersionCheckResult({
    required this.type,
    this.storeUrl,
    required this.latestVersion,
  });
}

class VersionCheckService {
  final String _apiUrl = Urls.versionMobile;

  Future<VersionCheckResult> checkVersion({http.Client? client}) async {
    final httpClient = client ?? PinnedHttpClient.createClient();
    try {
      // 1. Get Current Version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 2. Fetch Server Version (with timeout, fail-open on network errors)
      final response = await httpClient
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final config = data[0];
          final String latestVersion = config['latest_version'];
          final String minimumVersion = config['minimun_version'];
          final String linkPlayStore = config['link_playstore'];
          final String linkAppStore = config['link_appstore'];

          final storeUrl = Platform.isIOS ? linkAppStore : linkPlayStore;

          // 3. Compare Versions
          if (_isLowerThan(currentVersion, minimumVersion)) {
            return VersionCheckResult(
              type: UpdateType.mandatory,
              storeUrl: storeUrl,
              latestVersion: latestVersion,
            );
          } else if (_isLowerThan(currentVersion, latestVersion)) {
            return VersionCheckResult(
              type: UpdateType.optional,
              storeUrl: storeUrl,
              latestVersion: latestVersion,
            );
          }
        }
      }

      return VersionCheckResult(
        type: UpdateType.none,
        latestVersion: currentVersion,
      );
    } catch (e) {
      // Return none on error to allow login flow to continue (fail open)
      // or maybe log it.
      return VersionCheckResult(type: UpdateType.none, latestVersion: '');
    }
  }

  bool _isLowerThan(String current, String target) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final targetParts = target.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < currentParts.length ? currentParts[i] : 0;
        final t = i < targetParts.length ? targetParts[i] : 0;

        if (c < t) return true;
        if (c > t) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
