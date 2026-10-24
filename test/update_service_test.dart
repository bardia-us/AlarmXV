import 'package:alarm_xv/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> release({String version = 'v2.0.0', List<String>? files}) => {
    'tag_name': version, 'draft': false, 'prerelease': false,
    'html_url': 'https://github.com/bardia-us/AlarmXV/releases/tag/$version',
    'body': 'New features',
    'assets': (files ?? ['arm64-v8a', 'armeabi-v7a', 'universal'])
      .map((name) => {'name': 'AlarmXV-$version-$name.apk',
        'browser_download_url': 'https://github.com/bardia-us/AlarmXV/releases/download/$version/AlarmXV-$version-$name.apk'})
      .toList(),
  };

  test('version comparison prevents downgrade and respects prereleases', () {
    expect(AppVersion.parse('v2.0.0').compareTo(AppVersion.parse('2.0.0-preview.1')), greaterThan(0));
    expect(AppVersion.parse('1.10.0').compareTo(AppVersion.parse('1.9.9')), greaterThan(0));
    expect(AppVersion.parse('2.0.0+4').compareTo(AppVersion.parse('2.0.0+9')), 0);
    expect(AppVersion.parse('2.0.0-preview.10').compareTo(AppVersion.parse('2.0.0-preview.2')), greaterThan(0));
    expect(() => AppVersion.parse('not-a-version'), throwsFormatException);
  });

  test('release recommends ABI-compatible download then universal', () {
    final r = AlarmRelease.fromJson(release());
    expect(r.recommendedAsset(['arm64-v8a', 'armeabi-v7a'])?.abi, 'arm64-v8a');
    expect(r.recommendedAsset(['armeabi-v7a'])?.abi, 'armeabi-v7a');
    expect(r.recommendedAsset(['x86_64'])?.abi, 'universal');
    expect(AlarmRelease.fromJson(release(files: ['armeabi-v7a']))
      .recommendedAsset(['arm64-v8a', 'armeabi-v7a'])?.abi, 'armeabi-v7a');
  });

  test('release rejects unrelated hosts, repo paths, draft and prerelease', () {
    final bad = release();
    (bad['assets'] as List).add({'name': 'AlarmXV-arm64-v8a.apk',
      'browser_download_url': 'https://evil.example/AlarmXV.apk'});
    expect(AlarmRelease.fromJson(bad).assets.length, 3);
    expect(() => AlarmRelease.fromJson({...release(), 'draft': true}), throwsFormatException);
    expect(() => AlarmRelease.fromJson({...release(), 'prerelease': true}), throwsFormatException);
    expect(() => AlarmRelease.fromJson({...release(), 'html_url':
      'https://github.com/attacker/AlarmXV/releases/tag/v2'}), throwsFormatException);
    expect(AlarmRelease.isTrustedProjectUrl(Uri.parse('https://github.com/bardia-us/AlarmXV.evil/releases')), isFalse);
  });
}
