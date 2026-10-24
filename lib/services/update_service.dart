import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

class AppVersion implements Comparable<AppVersion> {
  AppVersion._(this.core, this.pre);
  final List<int> core;
  final List<String> pre;

  factory AppVersion.parse(String value) {
    final match = RegExp(
      r'^v?(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$',
    ).firstMatch(value);
    if (match == null) throw const FormatException('Invalid version');
    return AppVersion._([
      for (var i = 1; i <= 3; i++) int.parse(match.group(i)!),
    ], match.group(4)?.split('.') ?? []);
  }

  @override
  int compareTo(AppVersion other) {
    for (var i = 0; i < 3; i++) {
      final order = core[i].compareTo(other.core[i]);
      if (order != 0) return order;
    }
    if (pre.isEmpty || other.pre.isEmpty) {
      return pre.isEmpty == other.pre.isEmpty
          ? 0
          : pre.isEmpty
          ? 1
          : -1;
    }
    for (var i = 0; i < pre.length && i < other.pre.length; i++) {
      final left = int.tryParse(pre[i]);
      final right = int.tryParse(other.pre[i]);
      final order = left != null && right != null
          ? left.compareTo(right)
          : left != null
          ? -1
          : right != null
          ? 1
          : pre[i].compareTo(other.pre[i]);
      if (order != 0) return order;
    }
    return pre.length.compareTo(other.pre.length);
  }
}

class ReleaseAsset {
  const ReleaseAsset(this.name, this.url, this.abi);
  final String name;
  final Uri url;
  final String abi;
}

class AlarmRelease {
  const AlarmRelease({
    required this.version,
    required this.page,
    required this.notes,
    required this.assets,
  });
  final String version;
  final Uri page;
  final String notes;
  final List<ReleaseAsset> assets;

  static bool isTrustedProjectUrl(Uri uri) =>
      uri.scheme == 'https' &&
      uri.host == 'github.com' &&
      uri.userInfo.isEmpty &&
      (!uri.hasPort || uri.port == 443) &&
      uri.pathSegments.length >= 2 &&
      uri.pathSegments[0] == 'bardia-us' &&
      uri.pathSegments[1] == 'AlarmXV' &&
      !uri.pathSegments.any(
        (segment) =>
            segment == '.' ||
            segment == '..' ||
            segment.contains('/') ||
            segment.contains('\\'),
      );

  factory AlarmRelease.fromJson(Map<String, dynamic> json) {
    if (json['draft'] == true || json['prerelease'] == true) {
      throw const FormatException('Not a public stable release');
    }
    final version = json['tag_name'] as String;
    AppVersion.parse(version);
    final page = Uri.parse(json['html_url'] as String);
    if (!isTrustedProjectUrl(page) ||
        !page.path.startsWith('/bardia-us/AlarmXV/releases/')) {
      throw const FormatException('Untrusted release URL');
    }
    final assets = <ReleaseAsset>[];
    for (final item in (json['assets'] as List<dynamic>? ?? [])) {
      if (item is! Map<String, dynamic>) continue;
      final name = item['name'] as String? ?? '';
      final url = Uri.tryParse(item['browser_download_url'] as String? ?? '');
      if (url == null ||
          !isTrustedProjectUrl(url) ||
          !url.path.startsWith('/bardia-us/AlarmXV/releases/download/') ||
          !name.toLowerCase().endsWith('.apk') ||
          !url.path.toLowerCase().endsWith('.apk'))
        continue;
      final abi = name.contains('arm64-v8a')
          ? 'arm64-v8a'
          : name.contains('armeabi-v7a')
          ? 'armeabi-v7a'
          : name.contains('x86_64')
          ? 'x86_64'
          : name.toLowerCase().contains('universal') ||
                name == 'app-release.apk'
          ? 'universal'
          : null;
      if (abi != null) assets.add(ReleaseAsset(name, url, abi));
    }
    return AlarmRelease(
      version: version,
      page: page,
      notes: json['body'] as String? ?? '',
      assets: List.unmodifiable(assets),
    );
  }

  ReleaseAsset? recommendedAsset(List<String> supportedAbis) {
    for (final abi in supportedAbis) {
      for (final asset in assets) {
        if (asset.abi == abi) return asset;
      }
    }
    return assets.where((asset) => asset.abi == 'universal').firstOrNull;
  }
}

class InstalledAppInfo {
  const InstalledAppInfo({
    required this.versionName,
    required this.supportedAbis,
    this.lastSeenVersion = '',
  });
  final String versionName;
  final List<String> supportedAbis;
  final String lastSeenVersion;
}

/// Network access happens only after the user taps Check for updates.
class UpdateService {
  const UpdateService();
  static const projectUrl = 'https://github.com/bardia-us/AlarmXV';
  static const _channel = MethodChannel('alarm_xv/alarm_manager');

  Future<InstalledAppInfo> appInfo() async {
    final info = await _channel.invokeMapMethod<String, dynamic>('getAppInfo');
    return InstalledAppInfo(
      versionName: info?['versionName'] as String? ?? '2.0.0-preview.1',
      supportedAbis: (info?['supportedAbis'] as List<dynamic>? ?? [])
          .cast<String>(),
      lastSeenVersion: info?['lastSeenVersion'] as String? ?? '',
    );
  }

  Future<void> markWhatsNewSeen(String version) =>
      _channel.invokeMethod<void>('markWhatsNewSeen', version);

  Future<void> openUrl(Uri url) {
    if (!AlarmRelease.isTrustedProjectUrl(url)) {
      throw const FormatException('Untrusted project URL');
    }
    return _channel.invokeMethod<void>('openExternalUrl', url.toString());
  }

  Future<AlarmRelease> latestRelease() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      return await (() async {
        final request = await client.getUrl(
          Uri.parse(
            'https://api.github.com/repos/bardia-us/AlarmXV/releases/latest',
          ),
        );
        request.followRedirects = false;
        request.headers.set(
          HttpHeaders.acceptHeader,
          'application/vnd.github+json',
        );
        request.headers.set(HttpHeaders.userAgentHeader, 'AlarmXV-Android');
        final response = await request.close();
        if (response.statusCode == 403 || response.statusCode == 429) {
          throw const HttpException(
            'درخواست‌ها زیاد بوده؛ کمی بعد دوباره امتحان کن.',
          );
        }
        if (response.statusCode != 200) {
          throw HttpException(
            'دریافت نسخه جدید ممکن نشد (${response.statusCode}).',
          );
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > 512 * 1024) {
            throw const FormatException('Release response too large');
          }
          bytes.addAll(chunk);
        }
        return AlarmRelease.fromJson(
          jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
        );
      })().timeout(const Duration(seconds: 15));
    } finally {
      client.close(force: true);
    }
  }
}
